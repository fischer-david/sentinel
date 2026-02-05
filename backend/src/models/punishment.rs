use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use time::OffsetDateTime;
use uuid::Uuid;
use crate::grpc::generated::Punishment;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct PunishmentWithTemplate {
    pub id: Uuid,
    pub player_uuid: Uuid,
    pub staff_uuid: Uuid,
    pub category_id: i32,
    pub template_id: i32,
    pub offense_number: i32,
    pub custom_reason: Option<String>,
    pub evidence: Option<String>,
    pub issued_at: OffsetDateTime,
    pub expires_at: Option<OffsetDateTime>,
    pub active: bool,
    pub revoked: bool,
    pub revoked_by: Option<Uuid>,
    pub revoked_at: Option<OffsetDateTime>,
    pub revoke_reason: Option<String>,
    pub appeal_id: Option<Uuid>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
    // Template fields
    pub punishment_type: String,
    pub duration_minutes: Option<i32>,
    pub reason_template: String,
    // Category fields
    pub category_name: String,
    pub severity_level: i32,
}

impl Into<Punishment> for PunishmentWithTemplate {
    fn into(self) -> Punishment {
        let reason = if let Some(reason) = self.custom_reason {
            reason
        } else {
            self.reason_template
        };

        Punishment {
            id: self.id.to_string(),
            r#type: self.punishment_type,
            player_id: self.player_uuid.to_string(),
            issued_at: self.issued_at.unix_timestamp(),
            expires_at: self.expires_at.map(|dt| dt.unix_timestamp()),
            active: self.active,
            reason,
        }
    }
}