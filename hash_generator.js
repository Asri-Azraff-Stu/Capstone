const bcrypt = require('bcryptjs');

// The new password you want to set
const newPassword = 'AdminFlow#2025!'; // <-- IMPORTANT: Change this to your desired new password

// Generate a salt and then hash the password
bcrypt.genSalt(10, (err, salt) => {
    if (err) {
        console.error('Error generating salt:', err);
        return;
    }
    bcrypt.hash(newPassword, salt, (err, hash) => {
        if (err) {
            console.error('Error hashing password:', err);
            return;
        }
        console.log('Your new password hash is:');
        console.log(hash);
    });
});