use actix_web::{HttpResponse, web};

#[derive(serde::Deserialize)]
pub struct FormData {
    _email: String,
    _name: String,
}

pub async fn subscribe(_form: web::Form<FormData>) -> HttpResponse {
    HttpResponse::Ok().finish()
}
