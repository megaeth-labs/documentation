---
title: Faucet
---


```{=html}
<div id="faucet-form-container">
    <form id="faucet-form">
        <p>
            <label for="wallet-address">Wallet Address:</label><br>
            <input 
                type="text" 
                id="wallet-address" 
                name="wallet-address" 
                placeholder="0x..." 
                required 
                pattern="^0x[a-fA-F0-9]{40}$"
                title="Please enter a valid wallet address (0x followed by 40 hexadecimal characters)"
                style="width: 100%; max-width: 500px; padding: 8px; margin: 8px 0; font-family: monospace; font-size:14px"
            >
        </p>
        
        <p>
            <div class="cf-turnstile" 
                 data-sitekey="0x4AAAAAABA4JXCaw9E2Py-9" 
                 data-callback="onTurnstileSuccess"
                 data-error-callback="onTurnstileError"
                 data-expired-callback="onTurnstileExpired">
            </div>
        </p>
        
        <p>
            <button type="submit" id="submit-btn" disabled>
                Get Testnet Tokens
            </button>
        </p>
    </form>
    
    <div id="result-container" style="display: none; margin-top: 20px;">
        <div id="result-content"></div>
    </div>
</div>

<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>

<script>
// Store the Turnstile token
let turnstileToken = null;

// Turnstile callback functions
function onTurnstileSuccess(token) {
    turnstileToken = token;
    document.getElementById('submit-btn').disabled = false;
    console.log('Turnstile verification successful');
}

function onTurnstileError(error) {
    turnstileToken = null;
    document.getElementById('submit-btn').disabled = true;
    console.error('Turnstile verification failed:', error);
}

function onTurnstileExpired() {
    turnstileToken = null;
    document.getElementById('submit-btn').disabled = true;
    console.log('Turnstile verification expired');
}

// Form submission handler
document.getElementById('faucet-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const submitBtn = document.getElementById('submit-btn');
    const resultContainer = document.getElementById('result-container');
    const resultContent = document.getElementById('result-content');
    const walletAddress = document.getElementById('wallet-address').value;
    
    // Check if Turnstile token is available
    if (!turnstileToken) {
        alert('Please complete the captcha verification first.');
        return;
    }
    
    // Disable submit button and show loading state
    submitBtn.disabled = true;
    submitBtn.textContent = 'Submitting...';
    
    try {
        const response = await fetch('https://faucet.megaeth.com', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                addr: walletAddress,
                token: turnstileToken
            })
        });
        
        const data = await response.json();
        
        // Display the result
        resultContainer.style.display = 'block';
        
        if (data.success) {
            resultContent.innerHTML = `
                <p><strong>Success!</strong> ${data.message}</p>
                <p><strong>Transaction Hash:</strong> <code>${data.txhash}</code></p>
                <p>You can view your transaction on the <a href="https://megaexplorer.xyz/tx/${data.txhash}" target="_blank">block explorer</a>.</p>
            `;
        } else {
            resultContent.innerHTML = `
                <p><strong>Error:</strong> ${data.message}</p>
            `;
        }
        
    } catch (error) {
        console.error('Request failed:', error);
        resultContainer.style.display = 'block';
        resultContent.innerHTML = `
            <p><strong>Request Failed:</strong> Unable to connect to the faucet service. Please try again later.</p>
        `;
    } finally {
        // Re-enable submit button
        submitBtn.disabled = false;
        submitBtn.textContent = 'Get Testnet Tokens';
    }
});
</script>
```
