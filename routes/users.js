const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sql = require('mssql');
const dotenv = require('dotenv');
const db = require('../config/db');
const authenticateToken = require('../middlewares/authenticate');
const crypto = require('crypto');
const generateUID = require('../utils/uidGenerator');
dotenv.config();

const router = express.Router();

/**
 * @swagger
 * /users/register:
 *   post:
 *     summary: Đăng ký người dùng mới
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
 *               email:
 *                 type: string
 *     responses:
 *       201:
 *         description: Người dùng đã được đăng ký thành công
 *       400:
 *         description: Thông tin không hợp lệ hoặc người dùng đã tồn tại
 *       500:
 *         description: Lỗi server
 */
router.post('/register', async (req, res) => {
	const { userid, password, email } = req.body;

	try {
		const pool = await db;
		const result = await pool.request()
			.input('userid', sql.NVarChar, userid)
			.input('email', sql.NVarChar, email)
			.query('SELECT * FROM users WHERE userid = @userid or email = @email');

		if (result.recordset.length > 0) {
			return res.status(400).send('Người dùng đã tồn tại');
		}

		const sha512HashPassword = crypto.createHash('sha512').update(password).digest('hex');
		await pool.request()
			.input('uid', sql.NVarChar, generateUID())
			.input('userid', sql.NVarChar, userid)
			.input('password_hash', sql.NVarChar, sha512HashPassword)
			.input('email', sql.NVarChar, email)
			.input('role', sql.NVarChar, 'user')
			.input('updated_at', sql.DateTime, null)
			.query('INSERT INTO users (uid, userid, password_hash, email, role,updated_at) VALUES (@uid, @userid, @password_hash, @email, @role,@updated_at)');

		res.status(201).send('Người dùng đã được đăng ký thành công');
	} catch (err) {
		console.error('Lỗi khi đăng ký người dùng:', err);
		res.status(500).send('Lỗi server');
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
		console.log(sha512HashPassword)

		// Kiểm tra mật khẩu
		const isMatch = sha512HashPassword === user.password_hash;
		console.log('x = ', isMatch)
		if (!isMatch) {
			return res.status(400).send('Mật khẩu không đúng');
		}

		// Sinh JWT
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

module.exports = router;
