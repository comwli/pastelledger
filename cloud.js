// Firebase 로그인 + Firestore 동기화. 설정값이 없으면 기기 저장 모드로 남음
import { firebaseConfig } from "./firebase-config.js";

const B = "https://www.gstatic.com/firebasejs/12.19.0/";

async function start() {
  const [{ initializeApp }, A, F] = await Promise.all([
    import(B + "firebase-app.js"), import(B + "firebase-auth.js"), import(B + "firebase-firestore.js")]);
  const app = initializeApp(firebaseConfig), auth = A.getAuth(app);
  const db = F.initializeFirestore(app, {
    ignoreUndefinedProperties: true,
    localCache: F.persistentLocalCache({ tabManager: F.persistentMultipleTabManager() })
  });
  // 지난 로그아웃 때 못 지운 Firestore 사본이 있으면 먼저 삭제
  if (localStorage.getItem("pl-clear-fs")) {
    try { await F.clearIndexedDbPersistence(db); localStorage.removeItem("pl-clear-fs"); } catch (e) {}
  }
  let ref = null, unsub = null;
  window.Cloud = {
    signIn: (e, p) => A.signInWithEmailAndPassword(auth, e, p),
    signUp: (e, p) => A.createUserWithEmailAndPassword(auth, e, p),
    reset: e => A.sendPasswordResetEmail(auth, e),
    // 안 올라간 기록을 먼저 올리고(최대 5초) 로그아웃 → 기기 안 Firestore 사본 삭제. 삭제 실패 시 false (다음 실행 때 재시도)
    signOut: async () => {
      const t = new Promise((_, no) => setTimeout(() => no({ code: "pending-writes" }), 5000));
      await Promise.race([F.waitForPendingWrites(db), t]);
      if (unsub) { unsub(); unsub = null; }
      await A.signOut(auth);
      try { await F.terminate(db); await F.clearIndexedDbPersistence(db); return true; }
      catch (e) { try { localStorage.setItem("pl-clear-fs", "1"); } catch (_) {} return false; }
    },
    save: d => ref ? F.setDoc(ref, d) : Promise.reject({ code: "no-user" })
  };
  A.onAuthStateChanged(auth, u => {
    if (unsub) { unsub(); unsub = null; }
    ref = u ? F.doc(db, "users", u.uid, "data", "ledger") : null;
    window.onCloudUser(u ? u.email : null, u ? u.uid : null);
    if (!u) return;
    // 내가 방금 쓴 값의 반영(hasPendingWrites)은 건너뜀
    unsub = F.onSnapshot(ref, s => { if (!s.metadata.hasPendingWrites) window.onCloudData(s.exists() ? s.data() : null); },
      e => window.onCloudError(e));
  });
}

if (firebaseConfig) {
  window.onCloudReady(true);
  start().catch(e => window.onCloudError(e));
} else {
  window.onCloudReady(false);
}
