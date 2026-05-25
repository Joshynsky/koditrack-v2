// KodiTrack M-Pesa Callback Handler
// Processes incoming payment confirmations from Safaricom Daraja API
// This is the URL registered as CallBackURL with Safaricom

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Safaricom Result Codes
const RESULT_CODES = {
  SUCCESS: 0,
  INSUFFICIENT_BALANCE: 1,
  USER_CANCELLED: 1032,
  TIMEOUT: 1031,
  SYSTEM_ERROR: 1037,
} as const;

Deno.serve(async (req: Request) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers, status: 204 });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Only POST requests accepted" }),
      { headers, status: 405 }
    );
  }

  try {
    const body = await req.json();
    console.log("📥 Callback received:", JSON.stringify(body));

    // ────────────────────────────────────────
    // 1. Extract the callback payload
    // ────────────────────────────────────────
    const callback = body.Body?.stkCallback;
    
    if (!callback) {
      console.error("❌ Invalid callback format: missing Body.stkCallback");
      return new Response(
        JSON.stringify({ ResultCode: 1, ResultDesc: "Invalid callback format" }),
        { headers, status: 400 }
      );
    }

    const {
      MerchantRequestID,
      CheckoutRequestID,
      ResultCode,
      ResultDesc,
      CallbackMetadata,
    } = callback;

    console.log(`📋 MerchantRequestID: ${MerchantRequestID}`);
    console.log(`📋 CheckoutRequestID: ${CheckoutRequestID}`);
    console.log(`📋 ResultCode: ${ResultCode} - ${ResultDesc}`);

    // ────────────────────────────────────────
    // 2. Idempotency Check: Prevent duplicate processing
    // ────────────────────────────────────────
    if (CheckoutRequestID) {
      const { data: existing } = await supabase
        .from("payments")
        .select("id")
        .eq("reference", CheckoutRequestID)
        .limit(1);

      if (existing && existing.length > 0) {
        console.log("⚠️ Duplicate callback ignored:", CheckoutRequestID);
        return new Response(
          JSON.stringify({ ResultCode: 0, ResultDesc: "Already processed" }),
          { headers, status: 200 }
        );
      }
    }

    // ────────────────────────────────────────
    // 3. Handle by Result Code
    // ────────────────────────────────────────

    // ── SUCCESS ──
    if (ResultCode === RESULT_CODES.SUCCESS) {
      console.log("✅ Payment successful! Processing...");

      const metadata = CallbackMetadata?.Item || [];
      
      // Extract metadata fields
      const getMeta = (name: string) => {
        const item = metadata.find((m: any) => m.Name === name);
        return item?.Value?.toString() || null;
      };

      const amount = parseFloat(getMeta("Amount") || "0");
      const mpesaReceipt = getMeta("MpesaReceiptNumber") || `RAX${Date.now()}`;
      const txnDate = getMeta("TransactionDate") || new Date().toISOString();
      const phoneNumber = getMeta("PhoneNumber") || "";

      console.log("📊 Extracted metadata:", {
        amount,
        mpesaReceipt,
        txnDate,
        phoneNumber,
      });

      if (!phoneNumber || amount <= 0) {
        console.error("❌ Missing phone or amount in metadata");
        return new Response(
          JSON.stringify({ ResultCode: 1, ResultDesc: "Missing metadata fields" }),
          { headers, status: 400 }
        );
      }

      // ────────────────────────────────────────
      // 4. Look up tenant by phone number
      // ────────────────────────────────────────
      const phoneFormatted = phoneNumber.startsWith("254") 
        ? "0" + phoneNumber.slice(3) 
        : phoneNumber;

      console.log(`🔍 Looking up tenant: ${phoneNumber} → ${phoneFormatted}`);

      const { data: tenant, error: lookupError } = await supabase
        .from("tenants")
        .select("id, name, property_id")
        .eq("phone", phoneFormatted)
        .single();

      if (lookupError || !tenant) {
        // Try the international format
        const { data: tenant2 } = await supabase
          .from("tenants")
          .select("id, name, property_id")
          .eq("phone", phoneNumber)
          .single();

        if (!tenant2) {
          console.log("⚠️ No tenant found for phone:", phoneNumber);
          // Still return success to Safaricom — we logged the payment
          return new Response(
            JSON.stringify({ 
              ResultCode: 0, 
              ResultDesc: "Callback received. No tenant matched — logged for manual review." 
            }),
            { headers, status: 200 }
          );
        }

        // Use the second lookup result
        await insertPayment(tenant2.id, amount, txnDate, mpesaReceipt, CheckoutRequestID, tenant2.name);
      } else {
        await insertPayment(tenant.id, amount, txnDate, mpesaReceipt, CheckoutRequestID, tenant.name);
      }

      return new Response(
        JSON.stringify({ ResultCode: 0, ResultDesc: "Payment processed successfully" }),
        { headers, status: 200 }
      );
    }

    // ── USER CANCELLED ──
    if (ResultCode === RESULT_CODES.USER_CANCELLED) {
      console.log("🚫 User cancelled the transaction");
      return new Response(
        JSON.stringify({ ResultCode: 0, ResultDesc: "Cancellation logged" }),
        { headers, status: 200 }
      );
    }

    // ── TIMEOUT ──
    if (ResultCode === RESULT_CODES.TIMEOUT) {
      console.log("⏰ Transaction timed out");
      return new Response(
        JSON.stringify({ ResultCode: 0, ResultDesc: "Timeout logged" }),
        { headers, status: 200 }
      );
    }

    // ── ALL OTHER ERRORS ──
    console.log(`❌ Unhandled ResultCode: ${ResultCode} - ${ResultDesc}`);
    return new Response(
      JSON.stringify({ ResultCode: 0, ResultDesc: `Result ${ResultCode} logged` }),
      { headers, status: 200 }
    );

  } catch (error) {
    console.error("❌ Callback processing error:", error);
    // Always return success to Safaricom to prevent retries
    return new Response(
      JSON.stringify({ ResultCode: 0, ResultDesc: "Internal processing — logged" }),
      { headers, status: 200 }
    );
  }
});

// ────────────────────────────────────────
// Helper: Insert payment record
// ────────────────────────────────────────
async function insertPayment(
  tenantId: string,
  amount: number,
  txnDate: string,
  mpesaReceipt: string,
  checkoutRequestId: string,
  tenantName: string
) {
  const { error } = await supabase.from("payments").insert({
    tenant_id: tenantId,
    amount: amount,
    payment_date: txnDate.split("T")[0],
    payment_method: "M-Pesa",
    reference: mpesaReceipt,
    notes: `Auto-recorded via M-Pesa callback. CheckoutID: ${checkoutRequestId}`,
  });

  if (error) {
    console.error("❌ Failed to insert payment:", error);
  } else {
    console.log(`✅ Payment recorded: KES ${amount} for ${tenantName}`);
    console.log(`   Receipt: ${mpesaReceipt}`);
    // SQL trigger automatically updates tenant balance
  }
}