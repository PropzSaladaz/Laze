"use client";
import { invoke } from "@tauri-apps/api/core";
import { QRCodeSVG } from "qrcode.react";
import { useCallback, useEffect, useRef, useState, type FormEvent } from "react";
import styles from "./PairingPanel.module.css";
interface Invite { id: string; code: string; expires_at: number; }
interface Phone { device_id: string; device_name: string; paired_at: number; }
function PairingIcon({ name }: { name: "phone" | "qr" | "close" }) {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {name === "phone" && <><rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 5h4M11 19h2"/></>}
    {name === "close" && <path d="m6 6 12 12M18 6 6 18"/>}
    {name === "qr" && <><rect x="3" y="3" width="6" height="6" rx="1"/><rect x="15" y="3" width="6" height="6" rx="1"/>
      <rect x="3" y="15" width="6" height="6" rx="1"/><path d="M15 15h3v3h3M21 15v-3M12 21h3v-3M12 12h3M3 12h6M12 3v6"/></>}
  </svg>;
}

export default function PairingPanel() {
  const [nameValue,setNameValue]=useState("");
  const [savedName,setSavedName]=useState("");
  const [nameLoading,setNameLoading]=useState(true);
  const [nameAvailable,setNameAvailable]=useState(false);
  const [nameSaving,setNameSaving]=useState(false);
  const [nameSaved,setNameSaved]=useState(false);
  const [nameError,setNameError]=useState("");
  const [phones,setPhones]=useState<Phone[]>([]);
  const [invite,setInvite]=useState<Invite|null>(null);
  const [error,setError]=useState("");
  const [busy,setBusy]=useState(false);
  const [now,setNow]=useState(Date.now());
  const alive=useRef(false);
  const currentInvite=useRef<Invite|null>(null);
  const dialog=useRef<HTMLDialogElement>(null);
  const knownPhones=useRef<Set<string>>(new Set());
  useEffect(() => {
    let active=true;
    invoke<string>("get_desktop_name")
      .then(name => { if(active) { setNameValue(name); setSavedName(name); setNameAvailable(true); } })
      .catch(() => { if(active) setNameError("Unable to load the computer name. Enter a new name and save it."); })
      .finally(() => { if(active) setNameLoading(false); });
    return () => { active=false; };
  },[]);
  async function saveName(event:FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const name=nameValue.trim();
    if(nameSaving || name===savedName) return;
    if(!name || Array.from(name).length>64 || new TextEncoder().encode(name).length>128) {
      setNameError("Use 1–64 characters, up to 128 bytes.");
      return;
    }
    setNameSaving(true);setNameError("");setNameSaved(false);
    try {
      const saved=await invoke<string>("set_desktop_name",{name});
      if(!alive.current) return;
      setNameValue(saved);setSavedName(saved);setNameAvailable(true);setNameSaved(true);
    } catch { if(alive.current) setNameError("Unable to save the computer name. Try again."); }
    finally { if(alive.current) setNameSaving(false); }
  }
  const cancel=useCallback(() => {
    const value=currentInvite.current;
    currentInvite.current=null;
    setInvite(null);
    if(value) void invoke("cancel_pairing_invite",{inviteId:value.id}).catch(()=>{});
  },[]);
  const refresh=useCallback(async () => {
    try {
      const list=await invoke<Phone[]>("list_paired_devices");
      if(!alive.current) return;
      if(currentInvite.current && list.some(phone=>!knownPhones.current.has(phone.device_id))) cancel();
      knownPhones.current=new Set(list.map(phone=>phone.device_id));
      setPhones(list);
      return true;
    } catch { if(alive.current) setError("Unable to read paired phones. Check that the desktop server is running."); return false; }
  },[cancel]);
  useEffect(() => {
    alive.current=true;
    void refresh();
    const timer=setInterval(()=>{setNow(Date.now());void refresh();},2000);
    return () => {
      alive.current=false;
      clearInterval(timer);
      const value=currentInvite.current;
      if(value) void invoke("cancel_pairing_invite",{inviteId:value.id}).catch(()=>{});
    };
  },[refresh]);
  useEffect(() => {
    if(invite && !dialog.current?.open) dialog.current?.showModal();
    if(invite && now>=invite.expires_at*1000) cancel();
  },[invite,now,cancel]);
  async function pair() {
    setBusy(true);setError("");
    try {
      if(!await refresh() || !alive.current) return;
      const value=await invoke<Invite>("create_pairing_invite");
      if(!alive.current) { void invoke("cancel_pairing_invite",{inviteId:value.id}).catch(()=>{});return; }
      currentInvite.current=value;
      setNow(Date.now());setInvite(value);
    } catch { if(alive.current) setError("Unable to create a pairing code. Start the server and try again."); }
    finally { if(alive.current) setBusy(false); }
  }
  async function forget(phone:Phone) {
    setBusy(true);setError("");
    try { await invoke("revoke_phone",{deviceId:phone.device_id});await refresh(); }
    catch { if(alive.current) setError("Unable to forget this phone. Its access has not been confirmed as removed."); }
    finally { if(alive.current) setBusy(false); }
  }
  const secondsRemaining = invite ? Math.max(0, Math.ceil(invite.expires_at - now / 1000)) : 0;
  const expiry = `${Math.floor(secondsRemaining / 60)}:${String(secondsRemaining % 60).padStart(2, "0")}`;
  const nameChanged=nameValue.trim()!==savedName;
  return (
    <section className={styles.panel} aria-labelledby="paired-phones-title">
      <div className={styles.nameSection}>
        <p className={styles.eyebrow}>THIS COMPUTER</p>
        <label className={styles.nameLabel} htmlFor="desktop-name">Computer name</label>
        <form className={styles.nameForm} onSubmit={event => void saveName(event)}>
          <input id="desktop-name" className={styles.nameInput} value={nameValue}
            maxLength={64} placeholder="Enter a computer name" disabled={nameLoading||nameSaving}
            onChange={event => {setNameValue(event.target.value);setNameSaved(false);setNameError("");}} />
          <button className={styles.saveButton} type="submit"
            disabled={nameLoading||nameSaving||!nameChanged}>
            {nameSaving ? "Saving…" : "Save name"}
          </button>
        </form>
        <p className={styles.nameHint}>
          {nameChanged ? "Save the name before creating a pairing code. " : ""}
          Newly paired phones will see this name. Phones already paired keep their saved name.
        </p>
        {nameSaved && <p className={styles.nameSuccess} role="status">Computer name saved.</p>}
        {nameError && <p className={styles.error} role="alert">{nameError}</p>}
      </div>
      <div className={styles.heading}>
        <div>
          <p className={styles.eyebrow}>SAVED CONNECTIONS</p>
          <h2 id="paired-phones-title">Paired phones <span className={styles.count}>{phones.length}</span></h2>
        </div>
        <button className={styles.primaryButton} onClick={() => void pair()} disabled={busy||nameLoading||nameSaving||!nameAvailable||nameChanged}>
          <PairingIcon name="qr"/><span>Pair phone</span>
        </button>
      </div>
      <p className={styles.description}>Pair once, then use Connect on your phone whenever you need it.</p>
      {error && <p role="alert" className={styles.error}>{error}</p>}
      {phones.length === 0 ? (
        <div className={styles.empty}>
          <span className={styles.deviceIcon}><PairingIcon name="phone"/></span>
          <div><h3>No phones paired yet</h3><p>Connect your first phone with a QR code.</p></div>
        </div>
      ) : (
        <ul className={styles.phones}>{phones.map(phone => (
          <li key={phone.device_id}>
            <span className={styles.deviceIcon}><PairingIcon name="phone"/></span>
            <div className={styles.deviceDetails}>
              <span className={styles.deviceName}>{phone.device_name}</span>
              <span className={styles.deviceMeta}>Paired {new Date(phone.paired_at * 1000).toLocaleDateString(undefined, { month: "short", day: "numeric" })}</span>
            </div>
            <button className={styles.forgetButton} disabled={busy}
              aria-label={`Forget ${phone.device_name}`} onClick={() => void forget(phone)}>Forget phone</button>
          </li>
        ))}</ul>
      )}
      <p className={styles.hint}>Forget phone ends its access to this computer until you pair it again.</p>
      {invite && (
        <dialog className={styles.dialog} ref={dialog}
          onCancel={event => { event.preventDefault(); cancel(); }} aria-labelledby="pair-title"
          aria-describedby="pair-description">
          <div className={styles.dialogHeading}>
            <div><p className={styles.eyebrow}>NEW CONNECTION</p><h2 id="pair-title">Pair your phone</h2></div>
            <button className={styles.closeButton} autoFocus onClick={cancel} aria-label="Close pairing">
              <PairingIcon name="close"/>
            </button>
          </div>
          <p id="pair-description" className={styles.description}>Open <strong>Pair computer</strong> on your phone and scan this code.</p>
          <div className={styles.qr}><QRCodeSVG value={invite.code} size={244} level="M" marginSize={4}/></div>
          <div className={styles.expiry} role="timer" aria-label={`Pairing code expires in ${secondsRemaining} seconds`}>
            <span className={styles.expiryDot}/><span>Code expires in <strong>{expiry}</strong></span>
          </div>
          <details className={styles.manualCode}>
            <summary>Use a pairing code instead</summary>
            <p>Paste this into the phone app’s pairing-code field.</p>
            <textarea className={styles.codeField} readOnly aria-label="Pairing code" value={invite.code}
              onFocus={event => event.target.select()} spellCheck={false}/>
          </details>
          <p className={styles.dialogHint}>Only pair a phone you want to control this computer.</p>
        </dialog>
      )}
    </section>
  );
}
