// KodiTrack STK Push Processor
// Real Safaricom Daraja API integration
// Endpoint: https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest

// Environment variables (set via Supabase secrets):
// MPESA_CONSUMER_KEY
// MPESA_CONSUMER_SECRET
// MPESA_SHORTCODE (Paybill or Till number)
// MPESA_PASSKEY
// MPESA_ENVIRONMENT ("sandbox" or "production")

const DARAJA_AUTH_URL = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
const DARAJA_STK_URL = "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest";

// Sandbox endpoints
const DARAJA_AUTH_SANDBOX = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
const DARAJA_STK_SANDBOX = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest";

Deno.serve(async (req: Request) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
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
    console.log("📲 STK Push request:", JSON.stringify(body));

    // ────────────────────────────────────────
    // 1. Extract and validate inputs
    // ────────────────────────────────────────
    const phoneRaw = body.phone || body.PhoneNumber || body.phoneNumber || "";
    const amount = Math.round(parseFloat(body.amount || body.Amount || "0"));
    const accountRef = (body.reference || body.AccountReference || body.accountRef || `RENT${Date.now()}`).toString().slice(0, 12);
    const description = (body.description || body.TransactionDesc || "Rent payment").toString().slice(0, 13);

    if (!phoneRaw || amount <= 0) {
      return new Response(
        JSON.stringify({ error: "Phone number and valid amount are required" }),
        { headers, status: 400 }
      );
    }

    // ────────────────────────────────────────
    // 2. Sanitize phone number to 2547XXXXXXXX
    // ────────────────────────────────────────
    let phone = phoneRaw.replace(/\D/g, ""); // Remove non-digits
    
    // Handle common Kenyan formats
    if (phone.startsWith("0")) {
      phone = "254" + phone.slice(1); // 07XX → 2547XX
    } else if (phone.startsWith("7")) {
      phone = "254" + phone; // 7XX → 2547XX
    } else if (phone.startsWith("1")) {
      phone = "254" + phone; // 1XX → 2541XX
    }
    
    // Validate
    if (!phone.startsWith("254") || phone.length !== 12) {
      return new Response(
        JSON.stringify({ error: `Invalid phone format: ${phoneRaw}. Expected 2547XXXXXXXX` }),
        { headers, status: 400 }
      );
    }

    console.log("📱 Sanitized phone:", phone);

    // ────────────────────────────────────────
    // 3. Get environment config
    // ────────────────────────────────────────
    const env = Deno.env.get("MPESA_ENVIRONMENT") || "sandbox";
    const consumerKey = Deno.env.get("MPESA_CONSUMER_KEY") || "";
    const consumerSecret = Deno.env.get("MPESA_CONSUMER_SECRET") || "";
    const shortcode = Deno.env.get("MPESA_SHORTCODE") || "174379";
    const passkey = Deno.env.get("MPESA_PASSKEY") || "";

    const authUrl = env === "production" ? DARAJA_AUTH_URL : DARAJA_AUTH_SANDBOX;
    const stkUrl = env === "production" ? DARAJA_STK_URL : DARAJA_STK_SANDBOX;

    console.log(`🔧 Environment: ${env}`);
    console.log(`🔗 Auth URL: ${authUrl}`);

    // ────────────────────────────────────────
    // 4. Generate OAuth2 Access Token
    // ────────────────────────────────────────
    const authString = btoa(`${consumerKey}:${consumerSecret}`);
    
    console.log("🔑 Requesting OAuth2 token...");
    console.log(`   Key: ${consumerKey.slice(0, 6)}...`);
    console.log(`   URL: ${authUrl}`);
    
    const tokenResponse = await fetch(authUrl, {
      method: "GET",
      headers: {
        "Authorization": `Basic ${authString}`,
      },
    });

    if (!tokenResponse.ok) {
      const statusCode = tokenResponse.status;
      const statusText = tokenResponse.statusText;
      let errText = "";
      try {
        errText = await tokenResponse.text();
      } catch (_) {
        errText = "Could not read response body";
      }
      console.error(`❌ Auth failed [${statusCode} ${statusText}]:`, errText);
      return new Response(
        JSON.stringify({ 
          error: "Failed to authenticate with Safaricom", 
          status: statusCode,
          statusText: statusText,
          details: errText,
          authUrl: authUrl
        }),
        { headers, status: 502 }
      );
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;
    console.log("✅ Access token obtained");

    // ────────────────────────────────────────
    // 5. Generate Password (Base64-encoded)
    // Formula: Base64(BusinessShortCode + Passkey + Timestamp)
    // ────────────────────────────────────────
    const timestamp = new Date().toISOString().replace(/[-:T.]/g, "").slice(0, 14);
    const passwordRaw = `${shortcode}${passkey}${timestamp}`;
    const password = btoa(passwordRaw);
    
    console.log("🔐 Password generated for timestamp:", timestamp);

    // ────────────────────────────────────────
    // 6. Build STK Push payload
    // ────────────────────────────────────────
    const stkPayload = {
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: amount.toString(),
      PartyA: phone,
      PartyB: shortcode,
      PhoneNumber: phone,
      CallBackURL: `${Deno.env.get("SUPABASE_URL")}/functions/v1/stk-callback`,
      AccountReference: accountRef,
      TransactionDesc: description,
    };

    console.log("📤 Sending STK Push:", JSON.stringify(stkPayload, null, 2));

    // ────────────────────────────────────────
    // 7. Send STK Push to Safaricom
    // ────────────────────────────────────────
    const stkResponse = await fetch(stkUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(stkPayload),
    });

    const stkData = await stkResponse.json();
    console.log("📥 Safaricom response:", JSON.stringify(stkData));

    if (!stkResponse.ok) {
      return new Response(
        JSON.stringify({ error: "STK Push failed", details: stkData }),
        { headers, status: 502 }
      );
    }

    // ────────────────────────────────────────
    // 8. Return response to the app
    // ────────────────────────────────────────
    return new Response(JSON.stringify(stkData), { headers, status: 200 });

  } catch (error) {
    console.error("❌ Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { headers, status: 500 }
    );
  }
});