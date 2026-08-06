import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, doc, setDoc } from 'firebase-admin/firestore';

const projectId = 'sge-sec-diarra';
const uid = '08qWAVq3lHXYQpRyHk9csindO7Z2';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();
await setDoc(doc(db, 'users', uid), { employeeId: uid }, { merge: true });
console.log('Updated employeeId for', uid);
