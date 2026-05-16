#!/bin/bash

# KodiTrack Simulation Lab v3
# Includes Daraja-format STK Push testing

PROJECT_URL="https://kkrprfwflyafxvxcvcxi.supabase.co"
FUNCTION_URL="$PROJECT_URL/functions/v1/mock-mpesa-service"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrcnByZndmbHlhZnh2eGN2Y3hpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njk4Mjc4NiwiZXhwIjoyMDkyNTU4Nzg2fQ.gi52YOomcG7MzqrsYmPtOXyMTAyM49qJjdLcBzjMtlY"
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

AUTH_HEADER="apikey: $ANON_KEY"
BEARER_HEADER="Authorization: Bearer $ANON_KEY"

trigger_payment() {
  local phone=$1
  local amount=$2
  local ref=$3
  local force_fail=${4:-false}
  
  if [ "$force_fail" = "true" ]; then
    echo -e "\n${RED}💀 Force Failure Mode${RESET}"
    echo -e "${YELLOW}📲 Sending STK Push to $phone for KES $amount...${RESET}"
    response=$(curl -s -X POST "$FUNCTION_URL" \
      -H "Content-Type: application/json" \
      -d "{\"phone\":\"$phone\",\"amount\":$amount,\"reference\":\"$ref\",\"force_failure\":true}")
  else
    echo -e "\n${YELLOW}📲 Sending STK Push to $phone for KES $amount...${RESET}"
    response=$(curl -s -X POST "$FUNCTION_URL" \
      -H "Content-Type: application/json" \
      -d "{\"phone\":\"$phone\",\"amount\":$amount,\"reference\":\"$ref\"}")
  fi
  
  echo -e "${GREEN}✅ Handshake:${RESET}"
  echo "$response" | python -m json.tool 2>/dev/null || echo "$response"
  
  echo -e "\n${CYAN}⏳ Waiting 4 seconds...${RESET}"
  sleep 5
  
  if [ "$force_fail" = "true" ]; then
    echo -e "${RED}❌ Payment FAILED (simulated). No changes made.${RESET}"
  else
    echo -e "${GREEN}✅ Payment recorded. Check the app!${RESET}"
  fi
}

view_payments() {
  echo -e "\n${YELLOW}📋 Last 10 payments...${RESET}"
  curl -s "$PROJECT_URL/rest/v1/payments?select=amount,payment_date,payment_method,reference,tenants(name,phone)&order=created_at.desc&limit=10" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null
}

view_balances() {
  echo -e "\n${YELLOW}💰 Tenant balances...${RESET}"
  curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone,opening_balance,base_rent,service_charge&order=name" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null
}

trigger_specific() {
  echo -e "\n${CYAN}Available tenants:${RESET}"
  curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone,opening_balance&order=name" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null
  
  echo ""
  read -p "Enter phone number: " phone
  read -p "Enter amount (KES): " amount
  read -p "Force failure? (y/n): " fail_choice
  read -p "Enter reference (optional): " ref
  
  if [ -z "$ref" ]; then ref="SIM$(date +%s)"; fi
  local force="false"
  if [ "$fail_choice" = "y" ] || [ "$fail_choice" = "Y" ]; then force="true"; fi
  
  trigger_payment "$phone" "$amount" "$ref" "$force"
}

trigger_random() {
  curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=created_at.desc&limit=1" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" > tenant.json
  
  name=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['name'])" 2>/dev/null)
  phone=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['phone'])" 2>/dev/null)
  
  amount=$((RANDOM % 14000 + 1000))
  ref="SIM$(date +%s)"
  
  echo -e "${CYAN}🎲 Random: $name ($phone) - KES $amount${RESET}"
  trigger_payment "$phone" "$amount" "$ref" "false"
}

trigger_random_failure() {
  curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=created_at.desc&limit=1" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" > tenant.json
  
  name=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['name'])" 2>/dev/null)
  phone=$(python -c "import json; d=json.load(open('tenant.json')); print(d[0]['phone'])" 2>/dev/null)
  
  amount=$((RANDOM % 14000 + 1000))
  ref="FAIL$(date +%s)"
  
  echo -e "${RED}💀 Random Failure Test${RESET}"
  echo -e "${CYAN}🎲 $name ($phone) - KES $amount${RESET}"
  trigger_payment "$phone" "$amount" "$ref" "true"
}

trigger_bulk() {
  echo -e "\n${YELLOW}📦 Bulk Payment Simulation${RESET}"
  
  tenants=$(curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone,base_rent,service_charge,opening_balance&order=name" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER")
  
  count=$(echo "$tenants" | python -c "import sys,json; d=json.load(sys.stdin); print(len(d))" 2>/dev/null)
  echo -e "${CYAN}Found $count tenants${RESET}\n"
  
  echo "$tenants" | python -c "
import sys, json
tenants = json.load(sys.stdin)
for t in tenants:
    phone = t['phone']
    name = t['name']
    total = float(t['base_rent'] or 0) + float(t['service_charge'] or 0)
    balance = float(t['opening_balance'] or 0)
    due = total + max(balance, 0)
    print(f'{name}|{phone}|{due}')
" 2>/dev/null | while IFS='|' read -r name phone due; do
    amount=$(printf "%.0f" "$due")
    ref="BULK$(date +%s)"
    echo -e "  📲 $name ($phone): KES $amount"
    curl -s -X POST "$FUNCTION_URL" \
      -H "Content-Type: application/json" \
      -d "{\"phone\":\"$phone\",\"amount\":$amount,\"reference\":\"$ref\"}" > /dev/null
    sleep 1
  done
  
  echo ""
  echo -e "${CYAN}⏳ Waiting for payments to process...${RESET}"
  sleep 6
  echo -e "${GREEN}✅ Bulk simulation complete!${RESET}"
}

trigger_daraja_format() {
  echo -e "\n${CYAN}Available tenants:${RESET}"
  curl -s "$PROJECT_URL/rest/v1/tenants?select=name,phone&order=name" \
    -H "$AUTH_HEADER" -H "$BEARER_HEADER" | python -m json.tool 2>/dev/null

  echo ""
  read -p "Enter phone (2547XXXXXXXX): " phone
  read -p "Enter amount (KES): " amount
  read -p "Enter account ref: " ref

  echo -e "\n${YELLOW}📲 Sending Daraja-format STK Push...${RESET}"
  response=$(curl -s -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"BusinessShortCode\": \"174379\",
      \"Password\": \"MTc0Mzc5YmZiMjc5ZjlhYTliZGJjZjE1OGU5N2RkNzFhNDY3Y2QyZTBjODkzMDU5YjEwZjc4ZTZiNzJhZGExZWQyYzkxOTIwMjYwNTE2MTIwMDAw\",
      \"Timestamp\": \"$(date +%Y%m%d%H%M%S)\",
      \"TransactionType\": \"CustomerPayBillOnline\",
      \"Amount\": \"$amount\",
      \"PartyA\": \"$phone\",
      \"PartyB\": \"174379\",
      \"PhoneNumber\": \"$phone\",
      \"CallBackURL\": \"$FUNCTION_URL\",
      \"AccountReference\": \"$ref\",
      \"TransactionDesc\": \"Rent payment\"
    }")

  echo -e "${GREEN}✅ Daraja Handshake:${RESET}"
  echo "$response" | python -m json.tool 2>/dev/null || echo "$response"

  echo -e "\n${CYAN}⏳ Waiting for callback...${RESET}"
  sleep 5
  echo -e "${GREEN}✅ Check the app for the new payment!${RESET}"
}

while true; do
  clear
  echo -e "${BOLD}${GREEN}"
  echo "╔══════════════════════════════════════╗"
  echo "║     KodiTrack Simulation Lab v3     ║"
  echo "╚══════════════════════════════════════╝"
  echo -e "${RESET}"
  echo ""
  echo -e "  ${BOLD}1.${RESET} Trigger payment (random)"
  echo -e "  ${BOLD}2.${RESET} Trigger payment (specific)"
  echo -e "  ${BOLD}3.${RESET} ${RED}Trigger FAILED payment${RESET}"
  echo -e "  ${BOLD}4.${RESET} Bulk pay ALL tenants"
  echo -e "  ${BOLD}5.${RESET} View recent payments"
  echo -e "  ${BOLD}6.${RESET} View tenant balances"
  echo -e "  ${BOLD}7.${RESET} Daraja-format STK Push (real API)"
  echo -e "  ${BOLD}0.${RESET} Exit"
  echo ""
  read -p "Select an option: " choice
  
  case $choice in
    1) trigger_random ;;
    2) trigger_specific ;;
    3) trigger_random_failure ;;
    4) trigger_bulk ;;
    5) view_payments ;;
    6) view_balances ;;
    7) trigger_daraja_format ;;
    0) echo -e "\n${GREEN}Goodbye!${RESET}"; exit 0 ;;
    *) echo -e "\n${YELLOW}Invalid option${RESET}"; sleep 1 ;;
  esac
  
  echo ""
  read -p "Press Enter to continue..."
done