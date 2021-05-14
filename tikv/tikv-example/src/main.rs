use tikv_client::{Config, RawClient, Error};

#[tokio::main]
async fn main() -> Result<(), Error> {
    let config = Config::new(vec!["http://pd.tikv:2379"]);
    let client = RawClient::new(config)?;
    let key = "TiKV".as_bytes().to_owned();
    let value = "Works!".as_bytes().to_owned();

    client.put(key.clone(), value.clone()).await?;
    println!(
        "Put: {} => {}",
        std::str::from_utf8(&key).unwrap(),
        std::str::from_utf8(&value).unwrap()
    );

    let returned: Vec<u8> = client.get(key.clone()).await?
        .expect("Value should be present.").into();
    assert_eq!(returned, value);
    println!(
        "Get: {} => {}",
        std::str::from_utf8(&key).unwrap(),
        std::str::from_utf8(&value).unwrap()
    );
    Ok(())
}
