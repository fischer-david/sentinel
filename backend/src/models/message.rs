use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use time::OffsetDateTime;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct PunishmentMessage {
    pub id: i32,
    pub message_type: String,
    pub name: String,
    pub description: Option<String>,
    pub message_content: String,
    pub is_default: bool,
    pub active: bool,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}