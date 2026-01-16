use crate::grpc::generated::punishment_service_server::PunishmentService as GeneratedPunishmentService;
use crate::services::PunishmentService;
use std::sync::Arc;

pub struct GrpcPunishmentService {
    punishment_service: Arc<PunishmentService>
}

impl GrpcPunishmentService {
    pub fn new(punishment_service: Arc<PunishmentService>) -> Self {
        Self {
            punishment_service
        }
    }
}

#[tonic::async_trait]
impl GeneratedPunishmentService for GrpcPunishmentService {

}