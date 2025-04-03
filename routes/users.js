const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sql = require('mssql');
const dotenv = require('dotenv');
const db = require('../config/db');
const authenticateToken = require('../middlewares/authenticate');
const crypto = require('crypto');
const generateUID = require('../utils/uidGenerator');
const formatDate = require('../utils/formatDate');
const { equal } = require('assert');

dotenv.config();

const router = express.Router();

/**
 * @swagger
 * /users/register:
 *   post:
 *     summary: Register a new user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userid:
 *                 type: string
 *                 description: Unique user ID
 *               password:
 *                 type: string
 *                 description: User's password
 *               email:
 *                 type: string
 *                 description: User's email address
 *               full_name:
 *                 type: string
 *                 description: User's fullname
 *               phone:
 *                 type: string
 *                 description: User's phone
 *               address:
 *                 type: string
 *                 description: User's address
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Invalid data or user already exists
 *       500:
 *         description: Internal server error
 */

router.post('/register', async (req, res) => {
	const { userid, password, email, full_name, phone, address, role } = req.body;

	if (!userid || !password || !email) {
		return res.status(400).json({ message: 'User ID, Password, and Email are required.' });
	}

	try {
		const pool = await db;
		const existingUser = await pool.request()
			.input('userid', sql.NVarChar, userid)
			.input('email', sql.NVarChar, email)
			.query('SELECT 1 FROM users WHERE userid = @userid OR email = @email');

		if (existingUser.recordset.length > 0) {
			return res.status(400).json({ message: 'User already exists.' });
		}

		// Hash password using SHA-512
		const hashedPassword = crypto.createHash('sha512').update(password).digest('hex');

		// Insert new user
		await pool.request()
			.input('uid', sql.NVarChar, generateUID())
			.input('userid', sql.NVarChar, userid)
			.input('password_hash', sql.NVarChar, hashedPassword)
			.input('full_name', sql.NVarChar, full_name || '')
			.input('phone', sql.NVarChar, phone || '')
			.input('address', sql.NVarChar, address || '')
			.input('email', sql.NVarChar, email)
			.input('role', sql.NVarChar, role || 'customer')
			.input('updated_at', sql.DateTime, null)
			.query(`INSERT INTO users (uid, userid, password_hash, full_name, phone, address, email, role, updated_at)
					VALUES (@uid, @userid, @password_hash, @full_name, @phone, @address, @email, @role, @updated_at)`);

		res.status(201).json({ message: 'User registered successfully.' });
	} catch (err) {
		console.error('Error registering user:', err);
		res.status(500).json({ message: 'Internal server error.' });
	}
});

/**
 * @swagger
 * /users/login:
 *   post:
 *     summary: Đăng nhập người dùng và nhận JWT token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userid:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Đăng nhập thành công và trả về JWT token
 *       400:
 *         description: Mật khẩu không đúng hoặc người dùng không tồn tại
 *       500:
 *         description: Lỗi server
 */
router.post('/login', async (req, res) => {
	const { userid, password } = req.body;

	try {
		const pool = await db;
		const result = await pool.request()
			.input('userid', sql.NVarChar, userid)
			.query('SELECT * FROM users WHERE userid = @userid');

		if (result.recordset.length === 0) {
			return res.status(400).send('Người dùng không tồn tại');
		}

		const user = result.recordset[0];
		const sha512HashPassword = crypto.createHash('sha512').update(password).digest('hex');

		const isMatch = sha512HashPassword === user.password_hash;
		if (!isMatch) {
			return res.status(400).send('Mật khẩu không đúng');
		}

		const token = jwt.sign({ userid: user.userid, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
		res.json({ token });
	} catch (err) {
		console.error('Lỗi khi đăng nhập:', err);
		res.status(500).send('Lỗi server');
	}
});

/**
 * @swagger
 * /users/{userid}:
 *   get:
 *     security:
 *       - Bearer: []
 *     summary: Lấy thông tin người dùng theo ID
 *     parameters:
 *       - in: path
 *         name: userid
 *         required: true
 *         description: ID của người dùng cần lấy thông tin
 *     responses:
 *       200:
 *         description: Thành công, trả về thông tin người dùng
 *       401:
 *         description: Chưa xác thực
 *       404:
 *         description: Người dùng không tồn tại
 */
router.get('/:userid', authenticateToken, async (req, res) => {
	const userId = req.params.userid;

	try {
		const pool = await db;
		const result = await pool.request()
			.input('userid', sql.NVarChar, userId)
			.query('SELECT * FROM users WHERE userid = @userid');

		if (result.recordset.length > 0) {
			res.json(result.recordset[0]);
		} else {
			res.status(404).send('Người dùng không tồn tại');
		}
	} catch (err) {
		console.error('Lỗi khi lấy người dùng:', err);
		res.status(500).send('Lỗi server');
	}
});

/**
 * @swagger
 * /users/updateUser:
 *   put:
 *     summary: Chỉnh sửa thông tin người dùng
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userid:
 *                 type: string
 *               full_name:
 *                 type: string
 *               phone:
 *                 type: string
 *               address:
 *                 type: string
 *               email:
 *                 type: string
 *               role:
 *                 type: string
 *     responses:
 *       200:
 *         description: Đăng nhập thành công và trả về JWT token
 *       400:
 *         description: Mật khẩu không đúng hoặc người dùng không tồn tại
 *       500:
 *         description: Lỗi server
 */
router.put('/updateUser', authenticateToken, async (req, res) => {
	const { userid, full_name, phone, address, email, role } = req.body;

	if (!userid || !email) {
		return res.status(400).json({ message: 'User ID and Email are required.' });
	}

	try {
		const pool = await db;

		const userCheck = await pool.request()
			.input('userid', sql.NVarChar, userid)
			.query('SELECT uid FROM users WHERE userid = @userid');

		if (userCheck.recordset.length === 0) {
			return res.status(404).json({ message: 'Người dùng không tồn tại' });
		}

		const userId = userCheck.recordset[0].uid;
		const updatedAt = formatDate(new Date());
		console.log(updatedAt);
		// Update user information
		const updateResult = await pool.request()
			.input('uid', sql.NVarChar, userId)
			.input('full_name', sql.NVarChar, full_name || '')
			.input('phone', sql.NVarChar, phone || '')
			.input('address', sql.NVarChar, address || '')
			.input('email', sql.NVarChar, email)
			.input('role', sql.NVarChar, role || 'customer')
			.input('updated_at', sql.DateTime, updatedAt)
			.query(`UPDATE users
					SET full_name = @full_name, phone = @phone, address = @address,
					email = @email, role = @role, updated_at = @updated_at WHERE uid = @uid`);

		// Check if the update query affected any rows
		if (updateResult.rowsAffected[0] > 0) {
			return res.status(200).json({ message: 'Cập nhật thành công' });
		} else {
			return res.status(400).json({ message: 'Không có thay đổi nào được thực hiện' });
		}
	} catch (err) {
		console.error('Lỗi khi cập nhật người dùng:', err);
		return res.status(500).json({ message: 'Lỗi server, vui lòng thử lại sau.' });
	}
});

/**
 * @swagger
 * /users/updateRole:
 *   put:
 *     summary: Update Role
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userid:
 *                 type: string
 *               role:
 *                 type: string
 *     responses:
 *       200:
 *         description: Update Role Success
 *       400:
 *         description: User does not exist
 *       500:
 *         description: Server error
 */
router.put('/updateRole', authenticateToken, async (req, res) => {
	const { userid, role } = req.body;
	const invalidRoles = ['customer', 'user', 'admin', 'manager', 'guest'];

	if (!userid) {
		return res.status(400).json({ message: 'User ID is required.' });
	}

	try {
		if (!invalidRoles.includes(role.trim().toString())) {
			return res.status(404).json({ message: 'Role is invalid' });
		}
		const pool = await db;
		const userCheck = await pool.request()
			.input('userid', sql.NVarChar, userid)
			.query('SELECT uid FROM users WHERE userid = @userid');

		if (userCheck.recordset.length === 0) {
			return res.status(404).json({ message: 'User does not exist' });
		}

		const userId = userCheck.recordset[0].uid;
		const updatedAt = formatDate(new Date());
		const updateResult = await pool.request()
			.input('uid', sql.NVarChar, userId)
			.input('role', sql.NVarChar, role || 'customer')
			.input('updated_at', sql.DateTime, updatedAt)
			.query(`UPDATE users SET role = @role, updated_at = @updated_at WHERE uid = @uid`);

		if (updateResult.rowsAffected[0] > 0) {
			return res.status(200).json({ message: 'Update Success' });
		} else {
			return res.status(400).json({ message: 'No changes were made' });
		}
	} catch (err) {
		console.error('Error updating:', err);
		return res.status(500).json({ message: 'Server error, please try again later.' });
	}
});
module.exports = router;