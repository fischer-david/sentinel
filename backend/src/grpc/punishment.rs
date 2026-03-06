use crate::grpc::generated::punishment_service_server::PunishmentService as GeneratedPunishmentService;
use crate::grpc::generated::{ChatMessage, DisconnectMessage, GetLivePunishmentsRequest, GetLivePunishmentsResponse, GetPlayerLoginRequest, GetPlayerLoginResponse, Punishment, PunishmentsWithDetails};
use crate::handler::BroadcastHandler;
use crate::models::PunishmentWithTemplate;
use crate::services::{BroadcastService, MessageService, PunishmentService};
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use tokio_stream::StreamExt;
use tonic::{Request, Response, Status, Streaming};
use uuid::Uuid;

pub struct GrpcPunishmentService {
    punishment_service: Arc<PunishmentService>,
    message_service: Arc<MessageService>,
    broadcast_service: Arc<BroadcastService>,
}

impl GrpcPunishmentService {
    pub fn new(
        punishment_service: Arc<PunishmentService>,
        message_service: Arc<MessageService>,
        broadcast_service: Arc<BroadcastService>,
    ) -> Self {
        Self {
            punishment_service,
            message_service,
            broadcast_service,
        }
    }
}

impl GrpcPunishmentService {
    async fn handle_player_status_change(
        broadcast_handler: &BroadcastHandler<Uuid, PunishmentWithTemplate>,
        identifier: &Uuid,
        request: &GetLivePunishmentsRequest,
    ) -> Result<(), String> {
        let player_id = Uuid::from_str(&request.player_id)
            .map_err(|e| format!("Invalid player ID: {}", e))?;

        if request.online {
            Ok(broadcast_handler.add_key_to_listener(identifier, player_id).await)
        } else {
            Ok(broadcast_handler.remove_key_from_listener(identifier, player_id).await)
        }
    }

    async fn create_punishment_response(
        message_service: &MessageService,
        punishment: &PunishmentWithTemplate,
    ) -> Result<GetLivePunishmentsResponse, String> {
        let punishment_type = &punishment.punishment_type;
        let reason = &punishment.reason;

        let disconnect_message = if punishment_type.contains("ban") || punishment_type.contains("kick") {
            Some(DisconnectMessage {
                message: message_service
                    .get_ban_message(reason, punishment.issued_at, punishment.expires_at)
                    .await
                    .map_err(|e| format!("Failed to get ban message: {}", e))?,
            })
        } else {
            None
        };

        let chat_message = if punishment_type.contains("mute") || punishment_type.contains("warn") {
            Some(ChatMessage {
                message: message_service
                    .get_mute_message(reason, punishment.expires_at)
                    .await
                    .map_err(|e| format!("Failed to get mute message: {}", e))?,
            })
        } else {
            None
        };

        Ok(GetLivePunishmentsResponse {
            punishments: Some(PunishmentsWithDetails {
                player_id: punishment.player_uuid.to_string(),
                disconnect_message,
                chat_message,
                punishment: vec![punishment.clone().into()],
            }),
        })
    }
}

#[tonic::async_trait]
impl GeneratedPunishmentService for GrpcPunishmentService {
    async fn get_player_login(
        &self,
        request: Request<GetPlayerLoginRequest>,
    ) -> Result<Response<GetPlayerLoginResponse>, Status> {
        let request = request.into_inner();
        let punishments = self
            .punishment_service
            .get_active_punishments(&request.player_id)
            .await
            .map_err(|e| Status::internal(format!("Failed to get active punishments: {}", e)))?;

        let grpc_punishments: Vec<Punishment> = punishments
            .iter()
            .map(|p| p.clone().into())
            .collect();

        let mut chat_message = None;
        let mut disconnect_message = None;

        for punishment in &punishments {
            let punishment_type = &punishment.punishment_type;

            if disconnect_message.is_none() && punishment_type.contains("ban") {
                disconnect_message = Some(DisconnectMessage {
                    message: self
                        .message_service
                        .get_ban_message(&punishment.reason, punishment.issued_at, punishment.expires_at)
                        .await
                        .map_err(|e| Status::internal(format!("Failed to get ban message: {}", e)))?,
                });
            }

            if chat_message.is_none()
                && (punishment_type.contains("mute") || punishment_type.contains("warn"))
            {
                chat_message = Some(ChatMessage {
                    message: self
                        .message_service
                        .get_mute_message(&punishment.reason, punishment.expires_at)
                        .await
                        .map_err(|e| Status::internal(format!("Failed to get mute message: {}", e)))?,
                });
            }

            if disconnect_message.is_some() {
                break;
            }
        }

        Ok(Response::new(GetPlayerLoginResponse {
            punishments: Some(PunishmentsWithDetails {
                player_id: request.player_id,
                chat_message,
                disconnect_message,
                punishment: grpc_punishments,
            }),
        }))
    }

    type GetLivePunishmentsStream = ReceiverStream<Result<GetLivePunishmentsResponse, Status>>;

    async fn get_live_punishments(
        &self,
        request: Request<Streaming<GetLivePunishmentsRequest>>,
    ) -> Result<Response<Self::GetLivePunishmentsStream>, Status> {
        let (tx, rx) = mpsc::channel(128);
        let identifier = Uuid::new_v4();
        let message_service = Arc::clone(&self.message_service);
        let broadcast_handler = self.broadcast_service.punishment.clone();

        let mut broadcast_rx = broadcast_handler.start_broadcast_listener(&identifier).await;
        let mut request_stream = request.into_inner();

        let broadcast_handler_for_requests = broadcast_handler.clone();
        let tx_for_cleanup = tx.clone();
        tokio::spawn(async move {
            while let Some(result) = request_stream.next().await {
                match result {
                    Ok(req) => {
                        if let Err(e) = Self::handle_player_status_change(
                            &broadcast_handler_for_requests,
                            &identifier,
                            &req,
                        )
                        .await
                        {
                            eprintln!("Error handling player status change: {}", e);
                            let _ = tx_for_cleanup
                                .send(Err(Status::internal("Failed to update player status")))
                                .await;
                            break;
                        }
                    }
                    Err(e) => {
                        eprintln!("Error in request stream: {}", e);
                        let _ = tx_for_cleanup
                            .send(Err(Status::internal("Request stream error")))
                            .await;
                        break;
                    }
                }
            }
        });

        let tx_for_broadcast = tx.clone();
        tokio::spawn(async move {
            while let Ok(event) = broadcast_rx.recv().await {
                match Self::create_punishment_response(&message_service, &event.value).await {
                    Ok(response) => {
                        if tx_for_broadcast.send(Ok(response)).await.is_err() {
                            break;
                        }
                    }
                    Err(e) => {
                        eprintln!("Error creating punishment response: {}", e);
                        let _ = tx_for_broadcast
                            .send(Err(Status::internal("Failed to process punishment")))
                            .await;
                        break;
                    }
                }
            }
        });

        // Spawn cleanup task that runs when the receiver is dropped
        tokio::spawn(async move {
            tx.closed().await;
            broadcast_handler.remove_listener(&identifier).await;
        });

        Ok(Response::new(ReceiverStream::new(rx)))
    }
}