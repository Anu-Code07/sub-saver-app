import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();

async function addNotification(uid: string, data: {
  category: string;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
}) {
  await db.collection(`notifications/${uid}/items`).add({
    ...data,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export const onUserCreate = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  await db.doc(`userAchievements/${userId}`).set({
    badges: [],
    streaks: { onTimePayments: 0 },
    unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

export const sendRenewalReminders = onSchedule("every day 09:00", async () => {
  const now = new Date();
  const reminderDays = [7, 3, 1, 0];

  for (const days of reminderDays) {
    const target = new Date(now);
    target.setDate(target.getDate() + days);
    const start = new Date(target.setHours(0, 0, 0, 0));
    const end = new Date(target.setHours(23, 59, 59, 999));

    const snap = await db
      .collection("subscriptions")
      .where("renewalDate", ">=", start)
      .where("renewalDate", "<=", end)
      .where("status", "==", "active")
      .get();

    for (const doc of snap.docs) {
      const data = doc.data();
      const members: string[] = data.members ?? [];
      for (const uid of members) {
        await addNotification(uid, {
          category: "renewalReminder",
          title: `${data.name} renews ${days === 0 ? "today" : `in ${days} days`}`,
          body: `Your share for ${data.name} is due soon.`,
        });
      }
    }
  }
});

export const generateRecurringExpenses = onSchedule("every day 01:00", async () => {
  const now = new Date();
  const start = new Date(now);
  start.setHours(0, 0, 0, 0);
  const end = new Date(now);
  end.setHours(23, 59, 59, 999);

  const snap = await db
    .collection("subscriptions")
    .where("renewalDate", ">=", start)
    .where("renewalDate", "<=", end)
    .where("status", "==", "active")
    .get();

  for (const subDoc of snap.docs) {
    const sub = subDoc.data();
    if (!sub.groupId || !Array.isArray(sub.members) || sub.members.length === 0) continue;

    const expenseId = `${subDoc.id}_${start.toISOString().slice(0, 10)}`;
    const expenseRef = db.doc(`groups/${sub.groupId}/expenses/${expenseId}`);
    const existing = await expenseRef.get();
    if (existing.exists) continue;

    const share = Math.round((Number(sub.cost ?? 0) / sub.members.length) * 100) / 100;
    await expenseRef.set({
      subscriptionId: subDoc.id,
      amount: Number(sub.cost ?? 0),
      splitType: "equal",
      splits: sub.members.map((uid: string) => ({
        uid,
        amount: share,
        status: uid === sub.createdBy ? "paid" : "pending",
      })),
      paidBy: sub.createdBy,
      subscriptionName: sub.name,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});

export const sendPaymentReminders = onSchedule("every day 10:00", async () => {
  const groups = await db.collection("groups").get();
  for (const groupDoc of groups.docs) {
    const expenses = await groupDoc.ref
      .collection("expenses")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)))
      .get();

    for (const expenseDoc of expenses.docs) {
      const expense = expenseDoc.data();
      for (const split of expense.splits ?? []) {
        if (split.status !== "pending") continue;
        await addNotification(split.uid, {
          category: "dueReminder",
          title: `${expense.subscriptionName ?? "Subscription"} payment pending`,
          body: `Your share of ₹${split.amount} is still pending.`,
          metadata: { groupId: groupDoc.id, expenseId: expenseDoc.id },
        });
      }
    }
  }
});

export const generateAiReminder = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");

  const { subscriptionName, amount, tone, memberName } = request.data as {
    subscriptionName: string;
    amount: number;
    tone: string;
    memberName: string;
  };

  const tonePrefix: Record<string, string> = {
    friendly: `Hey ${memberName} 👋`,
    professional: `Dear ${memberName},`,
    funny: `Yo ${memberName} 😄`,
    aggressive: `${memberName}!`,
    passiveAggressive: `Oh ${memberName}...`,
  };

  const prefix = tonePrefix[tone] ?? tonePrefix.friendly;
  const message = `${prefix} ${subscriptionName} renewal is coming up. Your share is ₹${amount}.`;

  // Gemini API integration: set GEMINI_API_KEY in Firebase secrets
  // const geminiKey = process.env.GEMINI_API_KEY;
  // if (geminiKey) { ... call Gemini API ... }

  return { message };
});

export const onPaymentUpdate = onDocumentUpdated(
  "groups/{groupId}/expenses/{expenseId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;

    const groupId = event.params.groupId;
    const group = await db.doc(`groups/${groupId}`).get();
    const memberIds: string[] = group.data()?.memberIds ?? [];

    for (const uid of memberIds) {
      if (uid === after.paidBy) continue;
      await addNotification(uid, {
        category: "paymentReceived",
        title: "Payment update",
        body: `Expense for ${after.subscriptionName ?? "subscription"} was updated.`,
      });
    }
  }
);

export const onPaymentProofCreated = onDocumentCreated(
  "paymentProofs/{proofId}",
  async (event) => {
    const proof = event.data?.data();
    if (!proof) return;

    const group = await db.doc(`groups/${proof.groupId}`).get();
    const ownerId = group.data()?.ownerId as string | undefined;
    if (!ownerId) return;

    await addNotification(ownerId, {
      category: "paymentReceived",
      title: "Payment proof uploaded",
      body: "A member uploaded payment proof for review.",
      metadata: { proofId: event.params.proofId, groupId: proof.groupId },
    });
  }
);

export const onPaymentProofReviewed = onDocumentUpdated(
  "paymentProofs/{proofId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;

    await addNotification(after.uploadedBy, {
      category: "paymentReceived",
      title: `Payment proof ${after.status}`,
      body: after.reviewNote ?? "Your payment proof has been reviewed.",
      metadata: { proofId: event.params.proofId, groupId: after.groupId },
    });
  }
);

export const simplifyDebts = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");
  const { debts } = request.data as { debts: { from: string; to: string; amount: number }[] };

  const balances: Record<string, number> = {};
  for (const d of debts) {
    balances[d.from] = (balances[d.from] ?? 0) - d.amount;
    balances[d.to] = (balances[d.to] ?? 0) + d.amount;
  }

  const creditors: { id: string; amount: number }[] = [];
  const debtors: { id: string; amount: number }[] = [];

  for (const [id, bal] of Object.entries(balances)) {
    if (Math.abs(bal) < 0.01) continue;
    if (bal > 0) creditors.push({ id, amount: bal });
    else debtors.push({ id, amount: -bal });
  }

  const result: { from: string; to: string; amount: number }[] = [];
  let i = 0;
  let j = 0;

  while (i < debtors.length && j < creditors.length) {
    const amount = Math.min(debtors[i].amount, creditors[j].amount);
    if (amount > 0.01) {
      result.push({ from: debtors[i].id, to: creditors[j].id, amount: Math.round(amount * 100) / 100 });
    }
    debtors[i].amount -= amount;
    creditors[j].amount -= amount;
    if (debtors[i].amount < 0.01) i++;
    if (creditors[j].amount < 0.01) j++;
  }

  return { settlements: result };
});
