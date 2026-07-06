const response = http.request(`https://block.tonapi.io/v2/accounts/${addr}`, {
    method: "GET",
    headers: {
        'Authorization': 'Bearer ' + auth_token,
        'Content-Type': 'application/json'
    }
});

const accData = json(response.body);

// Keep nanoton balance as decimal string so Maestro formatter never applies Number
// float paths (which broke 2.265 TON → "2.26" with the legacy Math.floor(scale) approach).
output.balance = accData.balance != null ? String(accData.balance) : '0';
output.status = accData.status;
output.walletAddress = addr;
