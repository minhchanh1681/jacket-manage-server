const crypto = require('crypto');

function generateUID() {
	return crypto.randomBytes(16).toString('hex');
}

module.exports = generateUID;
