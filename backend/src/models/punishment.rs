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
    pub offense_number: i32,
    pub punishment_type: String,
    pub reason: String,
    pub evidence: Option<String>,
    pub note: Option<String>,
    pub issued_at: OffsetDateTime,
    pub expires_at: Option<OffsetDateTime>,
    pub active: bool,
    pub revoked: bool,
    pub revoked_by: Option<Uuid>,
    pub revoked_at: Option<OffsetDateTime>,
    pub revoke_reason: Option<String>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
    // Category fields (joined)
    pub category_name: String,
}

impl From<PunishmentWithTemplate> for Punishment {
    fn from(p: PunishmentWithTemplate) -> Self {
        Punishment {
            id: p.id.to_string(),
            r#type: p.punishment_type,
            player_id: p.player_uuid.to_string(),
            issued_at: p.issued_at.unix_timestamp(),
            expires_at: p.expires_at.map(|dt| dt.unix_timestamp()),
            active: p.active,
            reason: p.reason,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use time::OffsetDateTime;

    fn make_punishment(punishment_type: &str, reason: &str, expires_at: Option<OffsetDateTime>) -> PunishmentWithTemplate {
        PunishmentWithTemplate {
            id: Uuid::new_v4(),
            player_uuid: Uuid::new_v4(),
            staff_uuid: Uuid::new_v4(),
            category_id: 1,
            offense_number: 1,
            punishment_type: punishment_type.to_string(),
            reason: reason.to_string(),
            evidence: None,
            note: None,
            issued_at: OffsetDateTime::now_utc(),
            expires_at,
            active: true,
            revoked: false,
            revoked_by: None,
            revoked_at: None,
            revoke_reason: None,
            created_at: OffsetDateTime::now_utc(),
            updated_at: OffsetDateTime::now_utc(),
            category_name: "Cheating/Hacking".to_string(),
        }
    }

    #[test]
    fn into_punishment_preserves_reason() {
        let p = make_punishment("temp_ban", "Hacking detected", None);
        let id = p.id.to_string();
        let player_id = p.player_uuid.to_string();
        let proto: Punishment = p.into();
        assert_eq!(proto.reason, "Hacking detected");
        assert_eq!(proto.id, id);
        assert_eq!(proto.player_id, player_id);
        assert_eq!(proto.r#type, "temp_ban");
        assert!(proto.active);
        assert!(proto.expires_at.is_none());
    }

    #[test]
    fn into_punishment_maps_expires_at() {
        let expires = OffsetDateTime::now_utc() + time::Duration::days(30);
        let p = make_punishment("temp_ban", "Cheating", Some(expires));
        let proto: Punishment = p.into();
        assert!(proto.expires_at.is_some());
        assert_eq!(proto.expires_at.unwrap(), expires.unix_timestamp());
    }

    #[test]
    fn into_punishment_perm_ban_has_no_expiry() {
        let p = make_punishment("perm_ban", "Repeated cheating", None);
        let proto: Punishment = p.into();
        assert!(proto.expires_at.is_none());
        assert_eq!(proto.r#type, "perm_ban");
    }
}