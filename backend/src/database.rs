use crate::error::AppResult;
use dotenvy::var;
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub async fn connect_to_db() -> AppResult<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&var("DATABASE_URL").expect("DATABASE_URL is not set")).await?;

    Ok(pool)
}