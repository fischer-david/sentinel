use crate::grpc::generated::{authentication_service_server::AuthenticationService as GeneratedAuthenticationService, ChangePasswordRequest, ChangePasswordResponse, LoginRequest, LoginResponse, RefreshRequest, RefreshResponse};
use crate::models::PasswordChangeRequest;
use crate::services::PlayerService;
use std::sync::Arc;
use tonic::{Request, Response, Status};

pub struct GrpcAuthenticationService {
    player_service: Arc<PlayerService>,
}

impl GrpcAuthenticationService {
    pub fn new(player_service: Arc<PlayerService>) -> Self {
        Self { player_service }
    }
}

#[tonic::async_trait]
impl GeneratedAuthenticationService for GrpcAuthenticationService {
    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<LoginResponse>, Status> {
        let req = request.into_inner();

        let response = self.player_service.login_user(
            crate::models::player::LoginRequest {
                username: req.username,
                password: req.password,
            }
        ).await.map(|response| {
            LoginResponse {
                access_token: response.access_token,
                refresh_token: response.refresh_token,
            }
        }).map_err(|e| {
            Status::unauthenticated(format!("Authentication failed: {}", e))
        })?;

        Ok(Response::new(response))
    }

    async fn refresh(
        &self,
        request: Request<RefreshRequest>,
    ) -> Result<Response<RefreshResponse>, Status> {
        let req = request.into_inner();

        let response = self.player_service.refresh_user(
            crate::models::player::RefreshRequest {
                refresh_token: req.refresh_token,
            }
        ).await.map(|response| {
            RefreshResponse {
                access_token: response.access_token,
                refresh_token: response.refresh_token,
            }
        }).map_err(|e| {
            Status::unauthenticated(format!("Authentication failed: {}", e))
        })?;

        Ok(Response::new(response))
    }

    async fn change_password(&self, request: Request<ChangePasswordRequest>) -> Result<Response<ChangePasswordResponse>, Status> {
        let claims = match self.player_service.verify_request_allow_password_change(&request).await {
            Ok(claims) => claims,
            Err(error) => return Err(error),
        };

        let req = request.into_inner();

        let response = self.player_service.change_password(
            claims.sub,
            PasswordChangeRequest {
                new_password: req.new_password,
            }
        ).await.map(|response| {
            ChangePasswordResponse {
                access_token: response.access_token,
                refresh_token: response.refresh_token,
            }
        }).map_err(|e| {
            Status::internal(format!("Password change failed: {}", e))
        })?;

        Ok(Response::new(response))
    }
}