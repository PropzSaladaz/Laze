use std::{
    io::{self, Read, Write},
    net::TcpStream,
    time::{Duration, Instant},
};
pub const MAX_HANDSHAKE: usize = 2048;
pub enum ReadFrame {
    Idle,
    Eof,
    Data(Vec<u8>),
}
pub fn write_frame(stream: &mut TcpStream, bytes: &[u8]) -> io::Result<()> {
    if bytes.is_empty() || bytes.len() > 4096 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "Invalid frame length",
        ));
    }
    stream.write_all(&(bytes.len() as u32).to_be_bytes())?;
    stream.write_all(bytes)
}
fn read_rest(stream: &mut TcpStream, mut out: &mut [u8], deadline: Instant) -> io::Result<()> {
    while !out.is_empty() {
        let remaining = deadline
            .checked_duration_since(Instant::now())
            .ok_or_else(|| io::Error::new(io::ErrorKind::TimedOut, "Frame deadline exceeded"))?;
        stream.set_read_timeout(Some(remaining.min(Duration::from_secs(1))))?;
        match stream.read(out) {
            Ok(0) => {
                return Err(io::Error::new(
                    io::ErrorKind::UnexpectedEof,
                    "Incomplete frame",
                ))
            }
            Ok(n) => {
                let (_, rest) = out.split_at_mut(n);
                out = rest;
            }
            Err(e) if e.kind() == io::ErrorKind::Interrupted => continue,
            Err(e)
                if e.kind() == io::ErrorKind::WouldBlock || e.kind() == io::ErrorKind::TimedOut =>
            {
                continue
            }
            Err(e) => return Err(e),
        }
    }
    Ok(())
}
pub fn read_frame(stream: &mut TcpStream, max: usize) -> io::Result<ReadFrame> {
    stream.set_read_timeout(Some(Duration::from_secs(1)))?;
    let mut header = [0; 4];
    match stream.read(&mut header[..1]) {
        Ok(0) => return Ok(ReadFrame::Eof),
        Ok(_) => {}
        Err(e) if e.kind() == io::ErrorKind::TimedOut || e.kind() == io::ErrorKind::WouldBlock => {
            return Ok(ReadFrame::Idle)
        }
        Err(e) => return Err(e),
    }
    let deadline = Instant::now() + Duration::from_secs(3);
    read_rest(stream, &mut header[1..], deadline)?;
    let length = u32::from_be_bytes(header) as usize;
    if length == 0 || length > max {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "Invalid frame length",
        ));
    }
    let mut bytes = vec![0; length];
    read_rest(stream, &mut bytes, deadline)?;
    Ok(ReadFrame::Data(bytes))
}
pub fn read_json<T: serde::de::DeserializeOwned>(stream: &mut TcpStream) -> Result<T, String> {
    match read_frame(stream, MAX_HANDSHAKE).map_err(|_| "Authentication connection closed")? {
        ReadFrame::Data(bytes) => {
            serde_json::from_slice(&bytes).map_err(|_| "Invalid authentication message".into())
        }
        _ => Err("Authentication timed out or connection closed".into()),
    }
}
pub fn write_json<T: serde::Serialize>(stream: &mut TcpStream, value: &T) -> Result<(), String> {
    let bytes = serde_json::to_vec(value).map_err(|_| "Invalid authentication message")?;
    write_frame(stream, &bytes).map_err(|_| "Authentication connection closed".into())
}
