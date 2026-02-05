use crate::error::AppResult;
use crate::models::PunishmentMessage;
use sqlx::PgPool;
use std::collections::HashMap;
use time::{format_description, OffsetDateTime};

#[derive(Clone)]
pub struct MessageService {
    pool: PgPool,
}

impl MessageService {
    pub fn new(pool: PgPool) -> Self {
        Self {
            pool,
        }
    }

    pub async fn get_default_message(&self, message_type: &str) -> AppResult<Option<PunishmentMessage>> {
        let message = sqlx::query_as::<_, PunishmentMessage>(
            "SELECT * FROM punishment_messages WHERE message_type = $1 AND is_default = true AND active = true LIMIT 1"
        )
        .bind(message_type)
        .fetch_optional(&self.pool)
        .await?;

        Ok(message)
    }

    pub async fn get_mute_message(&self, reason: &str, expires_at: Option<OffsetDateTime>) -> AppResult<String> {
        self.get_punishment_message("mute", reason, None, expires_at, None, None, None, None).await
    }

    pub async fn get_ban_message(&self, reason: &str, issued_at: OffsetDateTime, expires_at: Option<OffsetDateTime>) -> AppResult<String> {
        self.get_punishment_message("ban", reason, Some(issued_at), expires_at, None, None, None, None).await
    }

    pub async fn get_kick_message(&self, reason: &str) -> AppResult<String> {
        self.get_punishment_message("kick", reason, None, None, None, None, None, None).await
    }

    pub async fn get_warn_message(&self, reason: &str, offense_number: Option<i32>, category_name: Option<&str>) -> AppResult<String> {
        self.get_punishment_message("warn", reason, None, None, offense_number, None, None, category_name).await
    }

    async fn get_punishment_message(
        &self,
        message_type: &str,
        reason: &str,
        issued_at: Option<OffsetDateTime>,
        expires_at: Option<OffsetDateTime>,
        offense_number: Option<i32>,
        player_name: Option<&str>,
        staff_name: Option<&str>,
        category_name: Option<&str>,
    ) -> AppResult<String> {
        let message_template = self.get_default_message(message_type).await?;

        let template = match message_template {
            Some(msg) => msg.message_content,
            None => {
                match message_type {
                    "mute" => self.get_fallback_mute_message(reason, expires_at),
                    "ban" => self.get_fallback_ban_message(reason, issued_at.unwrap_or_else(OffsetDateTime::now_utc), expires_at),
                    "kick" => format!("§r§e⚠️ §r§f§lYou have been kicked!\n§r\n§r§eReason: §f{}\n§r\n§r§7You may rejoin immediately", reason),
                    "warn" => format!("§r§6§l⚠️ WARNING\n§r\n§r§eReason: §f{}", reason),
                    _ => format!("§r§c{}", reason),
                }
            }
        };

        let template = template.replace(r"\n", "\n");
        let mut variables = HashMap::new();
        variables.insert("reason", reason.to_string());

        if let Some(player) = player_name {
            variables.insert("player_name", player.to_string());
        }

        if let Some(staff) = staff_name {
            variables.insert("staff_name", staff.to_string());
        }

        if let Some(offense) = offense_number {
            variables.insert("offense_number", offense.to_string());
        }

        if let Some(category) = category_name {
            variables.insert("category_name", category.to_string());
        }

        if let Some(issued) = issued_at {
            let format = format_description::parse("[month repr:short] [day], [year] • [hour]:[minute]").unwrap();
            let issued_formatted = issued.format(&format).unwrap_or_else(|_| "Unknown".to_string());
            variables.insert("issued_at", issued_formatted);
        }

        let expires_text = if let Some(expires) = expires_at {
            let now = OffsetDateTime::now_utc();
            let duration = expires - now;

            if duration.is_positive() {
                let time_left_formatted = format_time_remaining(duration);
                match message_type {
                    "mute" => format!("§r§eExpires in: §a{}", time_left_formatted),
                    "ban" => format!("§r§e⏰ Expires in: §r§a{}", time_left_formatted),
                    _ => format!("§r§eExpires in: §a{}", time_left_formatted),
                }
            } else {
                match message_type {
                    "mute" => "§r§eStatus: §c§lEXPIRED".to_string(),
                    "ban" => "§r§e⏰ Duration: §r§c§lEXPIRED".to_string(),
                    _ => "§r§eStatus: §c§lEXPIRED".to_string(),
                }
            }
        } else {
            match message_type {
                "mute" => "§r§eStatus: §c§lPERMANENT".to_string(),
                "ban" => "§r§e⏰ Duration: §r§c§lPERMANENT".to_string(),
                _ => "§r§eStatus: §c§lPERMANENT".to_string(),
            }
        };
        variables.insert("expires_text", expires_text);

        if let Some(expires) = expires_at {
            let now = OffsetDateTime::now_utc();
            let duration = expires - now;
            if duration.is_positive() {
                variables.insert("time_remaining", format_time_remaining(duration));
            } else {
                variables.insert("time_remaining", "Expired".to_string());
            }
        }

        let mut result = template;
        for (key, value) in variables {
            result = result.replace(&format!("{{{}}}", key), &value);
        }

        Ok(result)
    }

    fn get_fallback_mute_message(&self, reason: &str, expires_at: Option<OffsetDateTime>) -> String {
        let mut response = String::new();

        response.push_str("§r§6§l🔇 You are muted");
        response.push_str("§r\n");
        response.push_str("§r\n");

        response.push_str(&format!("§r§eReason: §f{}", reason));
        response.push_str("§r\n");

        if let Some(expires) = expires_at {
            let now = OffsetDateTime::now_utc();
            let duration = expires - now;

            if duration.is_positive() {
                let time_left_formatted = format_time_remaining(duration);
                response.push_str(&format!("§r§eExpires in: §a{}", time_left_formatted));
            }
        } else {
            response.push_str("§r§eStatus: §c§lPERMANENT");
        }

        response.push_str("§r\n");
        response.push_str("§r§7Contact support if this was issued in error");

        response
    }

    fn get_fallback_ban_message(&self, reason: &str, issued_at: OffsetDateTime, expires_at: Option<OffsetDateTime>) -> String {
        let mut response = String::new();
        response.push_str("§r§4━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        response.push_str("§r\n");
        response.push_str("§r§c  🔒 ");
        response.push_str("§r§f§lSENTINEL SECURITY");
        response.push_str("§r\n");
        response.push_str("§r§4━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        response.push_str("§r\n");
        response.push_str("§r\n");

        response.push_str("§r§4§l🚫 You have been banned!");
        response.push_str("§r\n");
        response.push_str("§r\n");

        response.push_str(&format!("§r§c{}", reason.replace(".", ". \n")));
        response.push_str("§r\n");
        response.push_str("§r\n");

        // Time information
        let format = format_description::parse("[month repr:short] [day], [year] • [hour]:[minute]").unwrap();
        let issued_at_formatted = issued_at.format(&format).unwrap();
        response.push_str("§r§e📅 Issued: ");
        response.push_str(&format!("§r§f{}", issued_at_formatted));
        response.push_str("§r\n");

        if let Some(expires) = expires_at {
            let now = OffsetDateTime::now_utc();
            let duration = expires - now;

            if duration.is_positive() {
                let time_left_formatted = format_time_remaining(duration);
                response.push_str("§r§e⏰ Expires in: ");
                response.push_str(&format!("§r§a{}", time_left_formatted));
            }
        } else {
            response.push_str("§r§e⏰ Duration: ");
            response.push_str("§r§c§lPERMANENT");
        }

        response.push_str("§r\n");
        response.push_str("§r\n");

        // Footer
        response.push_str("§r§8━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        response.push_str("§r\n");
        response.push_str("§r§7💬 Contact support if this was issued in error");
        response.push_str("§r\n");
        response.push_str("§r§8━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

        response
    }
}

fn format_time_remaining(duration: time::Duration) -> String {
    let total_seconds = duration.whole_seconds();
    let days = total_seconds / 86400;
    let hours = (total_seconds % 86400) / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;

    if days > 0 {
        format!("{}d {}h {}m", days, hours, minutes)
    } else if hours > 0 {
        format!("{}h {}m", hours, minutes)
    } else if minutes > 0 {
        format!("{}m {}s", minutes, seconds)
    } else {
        format!("{}s", seconds)
    }
}