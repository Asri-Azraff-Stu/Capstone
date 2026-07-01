const bcrypt = require('bcryptjs');

// Passwords to hash
const passwords = {
    admin: 'AdminFlow#2025!',
    user: 'UserPass@ProJ789'
};

async function generateHashes() {
    console.log('Generating password hashes...\n');
    
    for (const [type, password] of Object.entries(passwords)) {
        try {
            const hash = await bcrypt.hash(password, 10);
            console.log(`${type.toUpperCase()} Password: "${password}"`);
            console.log(`Hash: "${hash}"`);
            console.log('---');
        } catch (error) {
            console.error(`Error hashing ${type} password:`, error);
        }
    }
}

generateHashes();