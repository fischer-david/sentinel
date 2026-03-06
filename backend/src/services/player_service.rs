use crate::error::{AppError, AppResult};
use crate::models::player::*;
use chrono::{Duration, Utc};
use dotenvy::var;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use tonic::{Request, Status};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,              // subject (player UUID)
    pub username: String,
    pub token_type: TokenType,
    pub exp: i64,               // expiration time
    pub iat: i64,               // issued at
    pub staff: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum TokenType {
    Access,                 // Normal authenticated user
    PasswordChangeOnly,     // Limited access - only for password changes
    Refresh,                // Refresh token
}

pub struct PlayerService {
    pool: PgPool,
}

impl PlayerService {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn verify_request_allow_password_change<T>(&self, request: &Request<T>) -> Result<Claims, Status> {
        let authorization = request.metadata().get("authorization");
        if authorization.is_none() {
            return Err(Status::unauthenticated("Missing authorization header"));
        }

        let auth_header = authorization.unwrap().to_str().map_err(|_| {
            Status::unauthenticated("Invalid authorization header format")
        })?;

        let bearer_token = if let Some(token) = auth_header.strip_prefix("Bearer ") {
            token
        } else {
            return Err(Status::unauthenticated("Invalid authorization header format - Bearer token expected"));
        };

        let claims = self.validate_token(bearer_token).await.map_err(|_| {
            Status::unauthenticated("Invalid or expired token")
        })?;

        if claims.token_type == TokenType::Refresh {
            return Err(Status::permission_denied("Refresh tokens cannot be used for password changes"));
        }

        Ok(claims)
    }

    #[allow(dead_code)]
    pub async fn verify_request<T>(&self, request: &Request<T>) -> Result<Claims, Status> {
        let claims = self.verify_request_allow_password_change(request).await;

        match claims {
            Ok(claims) => {
                if claims.token_type == TokenType::PasswordChangeOnly {
                    return Err(Status::unauthenticated("Password change tokens cannot be used for authentication"));
                }

                Ok(claims)
            }
            Err(status) => Err(status)
        }
    }

    fn generate_jwt_token(&self, player: &Player, token_type: TokenType, duration_hours: i64) -> AppResult<String> {
        let now = Utc::now();
        let exp = now + Duration::hours(duration_hours);

        let claims = Claims {
            sub: player.uuid,
            username: player.username.clone(),
            token_type,
            exp: exp.timestamp(),
            iat: now.timestamp(),
            staff: player.staff,
        };

        let header = Header::new(Algorithm::HS256);
        let encoding_key = EncodingKey::from_secret(&var("JWT_SECRET").expect("JWT_SECRET is not set").as_ref());

        match encode(&header, &claims, &encoding_key) {
            Ok(token) => Ok(token),
            Err(e) => Err(AppError::InternalError(format!("Failed to generate JWT token: {}", e)).into()),
        }
    }

    pub async fn validate_token(&self, token: &str) -> AppResult<Claims> {
        let decoding_key = DecodingKey::from_secret(&var("JWT_SECRET").expect("JWT_SECRET is not set").as_ref());
        let validation = Validation::new(Algorithm::HS256);

        match decode::<Claims>(token, &decoding_key, &validation) {
            Ok(token_data) => {
                let claims = token_data.claims;

                let player_uuid = claims.sub;
                if let Some(player) = self.get_player_by_uuid(player_uuid).await? {
                    if let Some(invalidated_before) = player.tokens_invalidated_before {
                        if claims.iat < invalidated_before.timestamp() {
                            return Err(AppError::Unauthorized("Token has been invalidated".to_string()).into());
                        }
                    }
                }

                Ok(claims)
            },
            Err(_) => Err(AppError::Unauthorized("Invalid or expired token".to_string()).into()),
        }
    }

    pub async fn get_player_by_uuid(&self, uuid: Uuid) -> AppResult<Option<Player>> {
        let player = sqlx::query_as::<_, Player>(
            "SELECT * FROM players WHERE uuid = $1"
        )
            .bind(uuid)
            .fetch_optional(&self.pool)
            .await?;

        Ok(player)
    }

    pub async fn change_password(&self, player_uuid: Uuid, request: PasswordChangeRequest) -> AppResult<EnhancedLoginResponse> {
        use sha2::{Digest, Sha256};

        let player = self.get_player_by_uuid(player_uuid).await?;

        if let Some(player) = player {
            if request.new_password.len() < 8 {
                return Err(AppError::CustomValidationError("Password must be at least 8 characters long".to_string()).into());
            }

            let new_password_hash = format!("{:x}", Sha256::digest(request.new_password.as_bytes()));

            let result = sqlx::query(
                r#"
                UPDATE players
                SET password_hash = $1,
                    password_change_required = FALSE,
                    updated_at = NOW()
                WHERE uuid = $2
                "#,
            )
                .bind(&new_password_hash)
                .bind(player_uuid)
                .execute(&self.pool)
                .await?;

            if result.rows_affected() > 0 {
                let updated_player = Player {
                    uuid: player.uuid,
                    username: player.username,
                    password_hash: Some(new_password_hash),
                    password_change_required: false,
                    tokens_invalidated_before: player.tokens_invalidated_before,
                    staff: player.staff,
                    created_at: player.created_at,
                    updated_at: Utc::now(),
                };

                let access_token = self.generate_jwt_token(&updated_player, TokenType::Access, 24)?; // 24 hours validity
                let refresh_token = self.generate_jwt_token(&updated_player, TokenType::Refresh, 168)?; // 7 days validity

                Ok(EnhancedLoginResponse {
                    access_token,
                    refresh_token: Some(refresh_token),
                })
            } else {
                Err(AppError::InternalError("Failed to update password".to_string()).into())
            }
        } else {
            Err(AppError::NotFound("player not found".to_string()).into())
        }
    }

    pub async fn refresh_user(&self, request: RefreshRequest) -> AppResult<RefreshResponse> {
        let claims = self.validate_token(&request.refresh_token).await?;
        if claims.token_type != TokenType::Refresh {
            return Err(AppError::Unauthorized("Invalid token type for refresh".to_string()).into());
        }

        let player_uuid = claims.sub;
        let player = self.get_player_by_uuid(player_uuid).await?;

        if let Some(player) = player {
            if player.password_change_required {
                return Err(AppError::CustomValidationError(
                    "Password change required. Please change your password to continue.".to_string()
                ).into());
            }

            let access_token = self.generate_jwt_token(&player, TokenType::Access, 24)?; // 24 hours validity
            let refresh_token = self.generate_jwt_token(&player, TokenType::Refresh, 168)?; // 7 days validity

            Ok(RefreshResponse {
                access_token,
                refresh_token,
            })
        } else {
            Err(AppError::NotFound("player not found".to_string()).into())
        }
    }

    pub async fn login_user(&self, request: LoginRequest) -> AppResult<EnhancedLoginResponse> {
        use sha2::{Digest, Sha256};

        let password_hash = format!("{:x}", Sha256::digest(request.password.as_bytes()));
        let player = sqlx::query_as::<_, Player>(
            r#"
            SELECT * FROM players
            WHERE username ILIKE $1 AND password_hash = $2
            "#,
        )
            .bind(&request.username)
            .bind(&password_hash)
            .fetch_optional(&self.pool)
            .await?;

        if let Some(player) = player {
            if player.password_change_required {
                let access_token = self.generate_jwt_token(&player, TokenType::PasswordChangeOnly, 1)?; // 1 hour validity

                sqlx::query(
                    r#"
                    UPDATE players
                    SET updated_at = NOW()
                    WHERE uuid = $1
                    "#,
                )
                    .bind(player.uuid)
                    .execute(&self.pool)
                    .await?;

                return Ok(EnhancedLoginResponse {
                    access_token,
                    refresh_token: None,
                });
            }

            let access_token = self.generate_jwt_token(&player, TokenType::Access, 24)?; // 24 hours validity
            let refresh_token = self.generate_jwt_token(&player, TokenType::Refresh, 168)?; // 7 days validity for refresh

            sqlx::query(
                r#"
                UPDATE players
                SET updated_at = NOW()
                WHERE uuid = $1
                "#,
            )
                .bind(player.uuid)
                .execute(&self.pool)
                .await?;

            Ok(EnhancedLoginResponse {
                access_token,
                refresh_token: Some(refresh_token),
            })
        } else {
            Err(AppError::WrongCredentials("Invalid username or password".to_string()).into())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── TokenType ────────────────────────────────────────────────────────────

    #[test]
    fn token_types_are_distinct() {
        assert_ne!(TokenType::Access, TokenType::Refresh);
        assert_ne!(TokenType::Access, TokenType::PasswordChangeOnly);
        assert_ne!(TokenType::Refresh, TokenType::PasswordChangeOnly);
    }

    #[test]
    fn token_type_clone_is_equal() {
        let t = TokenType::Access;
        assert_eq!(t.clone(), TokenType::Access);
    }

    // ── Claims serde round-trip ──────────────────────────────────────────────

    #[test]
    fn claims_serialise_and_deserialise() {
        let claims = Claims {
            sub: Uuid::new_v4(),
            username: "TestPlayer".to_string(),
            token_type: TokenType::Access,
            exp: 9_999_999_999,
            iat: 1_000_000_000,
            staff: false,
        };

        let json = serde_json::to_string(&claims).expect("serialize");
        let decoded: Claims = serde_json::from_str(&json).expect("deserialize");

        assert_eq!(decoded.sub, claims.sub);
        assert_eq!(decoded.username, claims.username);
        assert_eq!(decoded.token_type, TokenType::Access);
        assert_eq!(decoded.exp, claims.exp);
        assert_eq!(decoded.iat, claims.iat);
        assert!(!decoded.staff);
    }

    #[test]
    fn staff_claims_serialise_correctly() {
        let claims = Claims {
            sub: Uuid::new_v4(),
            username: "AdminPlayer".to_string(),
            token_type: TokenType::Refresh,
            exp: 9_999_999_999,
            iat: 1_000_000_000,
            staff: true,
        };

        let json = serde_json::to_string(&claims).expect("serialize");
        let decoded: Claims = serde_json::from_str(&json).expect("deserialize");

        assert!(decoded.staff);
        assert_eq!(decoded.token_type, TokenType::Refresh);
    }

    #[test]
    fn password_change_only_token_type_round_trips() {
        let claims = Claims {
            sub: Uuid::new_v4(),
            username: "NeedsChange".to_string(),
            token_type: TokenType::PasswordChangeOnly,
            exp: 9_999_999_999,
            iat: 1_000_000_000,
            staff: false,
        };

        let json = serde_json::to_string(&claims).expect("serialize");
        let decoded: Claims = serde_json::from_str(&json).expect("deserialize");
        assert_eq!(decoded.token_type, TokenType::PasswordChangeOnly);
    }
}
