use crate::handler::BroadcastHandler;
use crate::models::PunishmentWithTemplate;
use uuid::Uuid;

pub struct BroadcastService {
    pub punishment: BroadcastHandler<Uuid, PunishmentWithTemplate>,
}

impl BroadcastService {
    pub fn new() -> Self {
        Self {
            punishment: BroadcastHandler::new()
        }
    }
}