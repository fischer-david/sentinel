use crate::error::AppResult;
use crate::models::PunishmentWithTemplate;
use sqlx::PgPool;
use uuid::Uuid;

pub struct PunishmentService {
    pool: PgPool,
}

impl PunishmentService {
    pub fn new(pool: PgPool) -> Self {
        Self {
            pool
        }
    }

    pub async fn get_active_punishments(&self, player_id: &str) -> AppResult<Vec<PunishmentWithTemplate>> {
        let player_uuid = Uuid::parse_str(player_id)?;

        let punishments = sqlx::query_as::<_, PunishmentWithTemplate>(
            r#"
            SELECT
                p.id,
                p.player_uuid,
                p.staff_uuid,
                p.category_id,
                p.offense_number,
                p.punishment_type,
                p.reason,
                p.evidence,
                p.note,
                p.issued_at,
                p.expires_at,
                p.active,
                p.revoked,
                p.revoked_by,
                p.revoked_at,
                p.revoke_reason,
                p.created_at,
                p.updated_at,
                pc.name AS category_name
            FROM punishments p
            INNER JOIN punishment_categories pc ON p.category_id = pc.id
            WHERE p.player_uuid = $1
              AND p.active = true
              AND p.revoked = false
              AND (p.expires_at IS NULL OR p.expires_at > NOW())
            ORDER BY p.issued_at DESC
            "#
        )
        .bind(player_uuid)
        .fetch_all(&self.pool)
        .await?;

        Ok(punishments)
    }
}