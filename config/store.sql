-- Tạo bảng quản lý danh mục sản phẩm
CREATE TABLE categories (
	category_id INT PRIMARY KEY IDENTITY(1,1),  -- Mã danh mục
	category_name NVARCHAR(100) NOT NULL,        -- Tên danh mục
	description NVARCHAR(255),                   -- Mô tả danh mục
	delete_flag BIT DEFAULT 0                    -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng quản lý sản phẩm
CREATE TABLE products (
	product_id INT PRIMARY KEY IDENTITY(1,1),      -- Mã sản phẩm
	name NVARCHAR(100) NOT NULL,                   -- Tên sản phẩm
	description NVARCHAR(255),                     -- Mô tả sản phẩm
	price DECIMAL(10, 2) NOT NULL,                 -- Giá sản phẩm
	size NVARCHAR(10),                            -- Kích thước
	color NVARCHAR(50),                           -- Màu sắc
	stock_quantity INT NOT NULL,                   -- Số lượng còn lại
	thumbnail NVARCHAR(255),                      -- Đường dẫn ảnh thumbnail
	image_1 NVARCHAR(255),                         -- Đường dẫn ảnh chi tiết 1
	image_2 NVARCHAR(255),                         -- Đường dẫn ảnh chi tiết 2
	image_3 NVARCHAR(255),                         -- Đường dẫn ảnh chi tiết 3
	category_id INT FOREIGN KEY REFERENCES categories(category_id),  -- Liên kết đến danh mục
	delete_flag BIT DEFAULT 0                      -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng quản lý người dùng
CREATE TABLE users (
	uid NVARCHAR(32) PRIMARY KEY,                  -- Mã người dùng (đổi thành NVARCHAR(32))
	userid NVARCHAR(16) UNIQUE NOT NULL,       -- Tên đăng nhập
	password_hash NVARCHAR(255) NOT NULL,          -- Mật khẩu đã mã hóa
	full_name NVARCHAR(100),                       -- Tên đầy đủ
	email NVARCHAR(100) UNIQUE NOT NULL,           -- Email
	phone NVARCHAR(20),                            -- Số điện thoại
	address NVARCHAR(255),                         -- Địa chỉ
	role NVARCHAR(50) NOT NULL DEFAULT 'customer',  -- Vai trò người dùng (customer, admin, v.v.)
	created_at DATETIME DEFAULT GETDATE(),         -- Thời gian tạo tài khoản
	updated_at DATETIME DEFAULT GETDATE(),         -- Thời gian cập nhật tài khoản
	invalid BIT DEFAULT 0,                          -- Cột kiểm tra người dùng bị khóa hay không
	delete_flag BIT DEFAULT 0
);

-- Tạo bảng quản lý quyền hạn của người dùng
CREATE TABLE roles (
	role_id INT PRIMARY KEY IDENTITY(1,1),         -- Mã quyền hạn
	role_name NVARCHAR(50) NOT NULL UNIQUE,         -- Tên quyền hạn (admin, customer, v.v.)
	description NVARCHAR(255),                     -- Mô tả quyền hạn
	delete_flag BIT DEFAULT 0                       -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng liên kết người dùng với quyền hạn
CREATE TABLE user_roles (
	uid NVARCHAR(32) FOREIGN KEY REFERENCES users(uid),    -- Mã người dùng
	role_id INT FOREIGN KEY REFERENCES roles(role_id),      -- Mã quyền hạn
	PRIMARY KEY (uid, role_id)                              -- Khóa chính kép
);

-- Tạo bảng quản lý đơn hàng
CREATE TABLE orders (
	order_id INT PRIMARY KEY IDENTITY(1,1),        -- Mã đơn hàng
	uid NVARCHAR(32) FOREIGN KEY REFERENCES users(uid),  -- Mã khách hàng
	order_date DATETIME DEFAULT GETDATE(),          -- Ngày đặt hàng
	total_amount DECIMAL(10, 2) NOT NULL,           -- Tổng giá trị đơn hàng
	status NVARCHAR(50) DEFAULT 'pending',          -- Trạng thái đơn hàng (pending, paid, failed)
	payment_status NVARCHAR(50) DEFAULT 'pending',  -- Trạng thái thanh toán của đơn hàng (pending, paid, failed)
	delete_flag BIT DEFAULT 0                       -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng chi tiết đơn hàng
CREATE TABLE order_details (
	order_detail_id INT PRIMARY KEY IDENTITY(1,1),  -- Mã chi tiết đơn hàng
	order_id INT FOREIGN KEY REFERENCES orders(order_id),  -- Mã đơn hàng
	product_id INT FOREIGN KEY REFERENCES products(product_id),  -- Mã sản phẩm
	quantity INT NOT NULL,                             -- Số lượng
	unit_price DECIMAL(10, 2) NOT NULL,                -- Giá sản phẩm tại thời điểm mua
	delete_flag BIT DEFAULT 0                          -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng quản lý thanh toán
CREATE TABLE payments (
	payment_id INT PRIMARY KEY IDENTITY(1,1),           -- Mã thanh toán
	order_id INT FOREIGN KEY REFERENCES orders(order_id), -- Mã đơn hàng
	payment_date DATETIME DEFAULT GETDATE(),             -- Ngày thanh toán
	payment_method NVARCHAR(50) NOT NULL,                -- Phương thức thanh toán (ví dụ: Credit Card, Cash, PayPal)
	amount DECIMAL(10, 2) NOT NULL,                      -- Số tiền thanh toán
	payment_status NVARCHAR(50) DEFAULT 'pending',       -- Trạng thái thanh toán (pending, completed, failed)
	transaction_id NVARCHAR(100),                         -- Mã giao dịch thanh toán (nếu có)
	payment_details NVARCHAR(255),                        -- Chi tiết thanh toán (ví dụ: thông tin thẻ, mã xác thực, v.v.)
	delete_flag BIT DEFAULT 0                             -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng quản lý phiên đăng nhập người dùng
CREATE TABLE user_sessions (
	session_id INT PRIMARY KEY IDENTITY(1,1),          -- Mã phiên
	uid NVARCHAR(32) FOREIGN KEY REFERENCES users(uid), -- Mã người dùng
	session_token NVARCHAR(255) NOT NULL,               -- Mã token phiên đăng nhập
	created_at DATETIME DEFAULT GETDATE(),              -- Thời gian tạo phiên đăng nhập
	expiration DATETIME                                  -- Thời gian hết hạn phiên
);
-- Tạo bảng quản lý quyền truy cập
CREATE TABLE permissions (
	permission_id INT PRIMARY KEY IDENTITY(1,1),      -- Mã quyền
	page_name NVARCHAR(100) NOT NULL,                  -- Tên trang/tab
	permission_type NVARCHAR(50) NOT NULL,             -- Loại quyền (view, edit, delete, v.v.)
	description NVARCHAR(255),                         -- Mô tả quyền
	delete_flag BIT DEFAULT 0                           -- Cờ xóa (0: không xóa, 1: đã xóa)
);

-- Tạo bảng liên kết quyền với vai trò
CREATE TABLE role_permissions (
	role_id INT FOREIGN KEY REFERENCES roles(role_id),          -- Mã quyền hạn (role)
	permission_id INT FOREIGN KEY REFERENCES permissions(permission_id),  -- Mã quyền
	PRIMARY KEY (role_id, permission_id)                         -- Khóa chính kép
);

DECLARE @i INT = 1;
DELETE FROM user_roles;
DELETE FROM users;
DBCC CHECKIDENT ('user_roles', RESEED, 0);
DBCC CHECKIDENT ('users', RESEED, 0);

WHILE @i <= 10000
BEGIN
	INSERT INTO users (uid, userid, password_hash, full_name, email, phone, address, role, created_at, updated_at, invalid, delete_flag)
	VALUES (
		REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', ''),  -- Tạo GUID, loại bỏ dấu gạch ngang, đảm bảo độ dài 32 ký tự
		'user' + RIGHT('00000' + CAST(@i AS NVARCHAR(12)), 12),  -- Tên đăng nhập (user001, user002, ...)
		CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONVERT(VARBINARY(255), '1')), 2), -- Mật khẩu đã mã hóa (ví dụ đơn giản)
		'user ' + CAST(@i AS NVARCHAR(20)),  -- Tên đầy đủ
		'user' + RIGHT('00000' + CAST(@i AS NVARCHAR(20)), 20) + '@example.com',  -- Email (user001@example.com, ...)
		'091234567' + CAST(@i AS NVARCHAR(11)),  -- Số điện thoại
		'address ' + CAST(@i AS NVARCHAR(20)),  -- Địa chỉ
		'customer',  -- Vai trò (customer)
		GETDATE(),  -- Thời gian tạo
		GETDATE(),  -- Thời gian cập nhật
		0,  -- Người dùng không bị khóa
		0   -- Không bị xóa
	);
	SET @i = @i + 1;
END;

delete from products
delete from categories
DBCC CHECKIDENT ('products', RESEED, 0);
DBCC CHECKIDENT ('categories', RESEED, 0);

INSERT INTO categories (category_name, description, delete_flag)
VALUES 
('Áo khoác nam', 'Danh mục áo khoác dành cho nam, phong cách thể thao và thời trang', 0),
('Áo khoác nữ', 'Danh mục áo khoác dành cho nữ, phong cách thanh lịch và nữ tính', 0),
('Áo khoác dạ', 'Danh mục áo khoác dạ dành cho cả nam và nữ, thích hợp cho mùa đông', 0),
('Áo khoác thể thao', 'Danh mục áo khoác thể thao dành cho người yêu thích vận động và thể dục', 0),
('Áo khoác jean', 'Danh mục áo khoác jean dành cho nam và nữ, phong cách trẻ trung, năng động', 0);

-- Thêm dữ liệu vào bảng products với 30 sản phẩm áo khoác
INSERT INTO products (name, description, price, size, color, stock_quantity, thumbnail, image_1, image_2, image_3, category_id, delete_flag)
VALUES 
('Áo khoác nam mùa đông', 'Áo khoác nam dày dặn, ấm áp, thích hợp cho mùa đông, màu đen', 799000, 'L', 'Đen', 50, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 1, 0),
('Áo khoác nam dạ', 'Áo khoác dạ nam, phong cách lịch lãm, màu xám', 1200000, 'M', 'Xám', 30, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 1, 0),
('Áo khoác nam thể thao', 'Áo khoác thể thao nam, màu xanh lá, chất liệu thấm mồ hôi', 650000, 'M', 'Xanh lá', 40, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 1, 0),
('Áo khoác jean nam', 'Áo khoác jean nam, phong cách trẻ trung, màu xanh', 600000, 'L', 'Xanh', 25, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 1, 0),
('Áo khoác nam gió', 'Áo khoác nam gió, màu đen, kiểu dáng thể thao', 550000, 'XL', 'Đen', 50, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 1, 0),
('Áo khoác nữ mùa đông', 'Áo khoác nữ dày, ấm áp, màu hồng', 950000, 'M', 'Hồng', 20, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 2, 0),
('Áo khoác nữ dạ', 'Áo khoác dạ nữ, kiểu dáng thanh lịch, màu nâu', 1200000, 'M', 'Nâu', 30, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 2, 0),
('Áo khoác nữ dáng dài', 'Áo khoác nữ dáng dài, màu xám, cực kỳ ấm áp', 1000000, 'L', 'Xám', 25, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 2, 0),
('Áo khoác nữ thể thao', 'Áo khoác nữ thể thao, kiểu dáng năng động, màu cam', 680000, 'M', 'Cam', 40, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 2, 0),
('Áo khoác nữ jean', 'Áo khoác jean nữ, phong cách trẻ trung, màu xanh nhạt', 650000, 'L', 'Xanh nhạt', 35, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 2, 0),
('Áo khoác dạ nữ', 'Áo khoác dạ nữ, kiểu dáng thanh lịch, màu đen', 1250000, 'M', 'Đen', 20, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 3, 0),
('Áo khoác dạ nam', 'Áo khoác dạ nam, kiểu dáng lịch lãm, màu xám', 1400000, 'L', 'Xám', 15, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 3, 0),
('Áo khoác dạ cao cấp', 'Áo khoác dạ cao cấp dành cho cả nam và nữ, màu nâu', 1500000, 'M', 'Nâu', 10, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 3, 0),
('Áo khoác dạ dáng dài', 'Áo khoác dạ dáng dài, cực kỳ ấm, màu đen', 1300000, 'M', 'Đen', 25, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 3, 0),
('Áo khoác dạ nữ sang trọng', 'Áo khoác dạ nữ, màu rượu vang, thiết kế sang trọng', 1450000, 'L', 'Rượu vang', 18, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 3, 0),
('Áo khoác thể thao nam', 'Áo khoác thể thao nam, màu đỏ, chất liệu thoáng mát', 700000, 'M', 'Đỏ', 45, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 4, 0),
('Áo khoác thể thao nữ', 'Áo khoác thể thao nữ, kiểu dáng năng động, màu xanh', 750000, 'M', 'Xanh', 30, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 4, 0),
('Áo khoác thể thao gió', 'Áo khoác thể thao gió, màu xám, chất liệu chống nước', 650000, 'L', 'Xám', 50, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 4, 0),
('Áo khoác thể thao unisex', 'Áo khoác thể thao unisex, màu cam sáng', 670000, 'M', 'Cam sáng', 35, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 4, 0),
('Áo khoác thể thao thời trang', 'Áo khoác thể thao thời trang, kiểu dáng hiện đại, màu đen', 800000, 'L', 'Đen', 40, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 4, 0),
('Áo khoác jean nam', 'Áo khoác jean nam, phong cách cá tính, màu xanh đậm', 700000, 'L', 'Xanh đậm', 20, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean nữ', 'Áo khoác jean nữ, thiết kế tinh tế, màu xanh', 690000, 'M', 'Xanh', 30, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean dáng dài', 'Áo khoác jean dáng dài, màu xanh nhạt', 750000, 'L', 'Xanh nhạt', 25, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean nữ dáng suông', 'Áo khoác jean nữ dáng suông, màu xanh đậm', 720000, 'M', 'Xanh đậm', 35, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean nam dáng suông', 'Áo khoác jean nam dáng suông, màu xanh cổ điển', 770000, 'L', 'Xanh cổ điển', 20, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean unisex', 'Áo khoác jean unisex, màu xám nhạt', 690000, 'M', 'Xám nhạt', 40, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0),
('Áo khoác jean phối nón', 'Áo khoác jean nam phối nón, màu đen', 650000, 'L', 'Đen', 50, 'link_to_thumbnail_image', 'link_to_image_1', 'link_to_image_2', 'link_to_image_3', 5, 0);
