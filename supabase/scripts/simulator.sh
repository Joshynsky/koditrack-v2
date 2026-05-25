#!/bin/bash

# KodiTrack Simulation Lab v3
PROJECT_URL="https://kkrprfwflyafxvxcvcxi.supabase.co"
FUNCTION_URL="$PROJECT_URL/functions/v1/mock-mpesa-service"
# Load from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi
ANON_KEY="${SUPABASE_SERVICE_ROLE_KEY}"
AUTH_HEADER="apikey: $ANON_KEY"
BEARER_HEADER="Authorization: Bearer $ANON_KEY"

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

trigger_payment() { local phone=$1; local amount=$2; local ref=$3; local ff=${4:-false}; if [ "$ff" = "true" ]; then echo -e "\n${RED}Force Failure${RESET}"; response=$(curl -s -X POST "$FUNCTION_URL" -H "Content-Type: application/json" -d "{\"phone\":\"$phone\",\"amount\":$amount,\"reference\":\"$ref\",\"force_failure\":true}"); else echo -e "\n${YELLOW}Sending STK Push: $phone KES $amount${RESET}"; response=$(curl -s -X POST "$FUNCTION_URL" -H "Content-Type: application/json" -d "{\"phone\":\"$phone\",\"amount\":$amount,\"reference\":\"$ref\"}"); fi; echo -e "${GREEN}Handshake:${RESET}"; echo "$response" | python -m json.tool 2>/dev/null || echo "$response"; echo -e "\n${CYAN}Waiting 4 seconds...${RESET}"; sleep 5; if [ "$ff" = "true" ]; then echo -e "${RED}FAILED (simulated)${RESET}"; else echo -e "${GREEN}Payment recorded!${RESET}"; fi; }

view_payments() { echo -e "\n${YELLOW}Last 10 payments:${RESET}"; curl -s "$PROJECT_URL/rest/v1/payments?select=amount,payment_date,payment_method,reference,tenants(name,phone)&order=created_at.desc&limit=10" -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null; }

view_balances() { echo -e "\n${YELLOW}Tenant balances:${RESET}"; curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone,opening_balance,base_rent,service_charge&order=name" -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null; }

trigger_random() { curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=created_at.desc&limit=1" -H "$AUTH_HEADER" -H "$BEARER_HEADER" > tenant.json; name=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['name'])" 2>/dev/null); phone=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['phone'])" 2>/dev/null); amount=$((RANDOM % 14000 + 1000)); echo -e "${CYAN}Random: $name ($phone) - KES $amount${RESET}"; trigger_payment "$phone" "$amount" "SIM$(date +%s)" "false"; }

trigger_random_failure() { curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=created_at.desc&limit=1" -H "$AUTH_HEADER" -H "$BEARER_HEADER" > tenant.json; name=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['name'])" 2>/dev/null); phone=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['phone'])" 2>/dev/null); amount=$((RANDOM % 14000 + 1000)); echo -e "${RED}Failure Test: $name ($phone)${RESET}"; trigger_payment "$phone" "$amount" "FAIL$(date +%s)" "true"; }

trigger_daraja_format() { echo -e "\n${CYAN}Tenants:${RESET}"; curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=name" -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null; echo ""; read -p "Phone (2547XXXXXXXX): " phone; read -p "Amount (KES): " amount; read -p "Ref: " ref; echo -e "\n${YELLOW}Sending Daraja-format STK Push...${RESET}"; response=$(curl -s -X POST "$FUNCTION_URL" -H "Content-Type: application/json" -d "{\"BusinessShortCode\":\"174379\",\"Amount\":\"$amount\",\"PartyA\":\"$phone\",\"PartyB\":\"174379\",\"PhoneNumber\":\"$phone\",\"AccountReference\":\"$ref\",\"TransactionDesc\":\"Rent\"}"); echo -e "${GREEN}Response:${RESET}"; echo "$response" | python -m json.tool 2>/dev/null || echo "$response"; echo -e "\n${CYAN}Waiting...${RESET}"; sleep 5; echo -e "${GREEN}Done!${RESET}"; }

while true; do
  clear
  echo -e "${BOLD}${GREEN}"
  echo "  KodiTrack Simulation Lab v3"
  echo -e "${RESET}"
  echo "  1. Random payment"
  echo "  2. Specific payment"
  echo "  3. FAILED payment"
  echo "  4. Bulk pay ALL"
  echo "  5. View payments"
  echo "  6. View balances"
  echo "  7. Daraja-format STK Push"
  echo "  0. Exit"
  echo ""
  read -p "Select: " choice
  case $choice in
    1) trigger_random ;;
    2) trigger_specific ;;
    3) trigger_random_failure ;;
    4) trigger_bulk ;;
    5) view_payments ;;
    6) view_balances ;;
    7) trigger_daraja_format ;;
    0) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid" ; sleep 1 ;;
  esac
  echo ""
  read -p "Press Enter..."
done
