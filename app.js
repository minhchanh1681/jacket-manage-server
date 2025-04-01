const express = require('express');
const dotenv = require('dotenv');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const usersRouter = require('./routes/users');
dotenv.config();

const app = express();

// Middleware để parse JSON body
app.use(express.json());

// Cấu hình Swagger
const swaggerOptions = {
  definition: {
	openapi: '3.0.0',
	info: {
		title: 'User API',
		version: '1.0.0',
		description: 'API để quản lý người dùng',
	},
  },
  apis: ['./routes/users.js'],
};

// Tạo tài liệu Swagger
const swaggerDocs = swaggerJsdoc(swaggerOptions);

// Đăng ký Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

// Đăng ký routes
app.use('/users', usersRouter);

// Khởi động server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
	console.log(`Server đang chạy tại http://localhost:${PORT}`);
	console.log(`Tài liệu API có sẵn tại http://localhost:${PORT}/api-docs`);
});
