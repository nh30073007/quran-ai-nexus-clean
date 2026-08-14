import sys
sys.path.insert(0, 'C:\\quran_ai_nexus\\backend')

from app.database import SessionLocal, Admin
from app.auth.password import hash_password
from datetime import datetime

db = SessionLocal()

admin = db.query(Admin).filter(Admin.username == 'admin').first()

if not admin:
    admin = Admin(
        username='admin',
        email='admin@quran.com',
        password=hash_password('admin123'),
        created_at=datetime.utcnow()
    )
    db.add(admin)
    db.commit()
    print("✅ Admin created successfully!")
    print("Username: admin")
    print("Password: admin123")
else:
    print("✅ Admin already exists!")
    print(f"Username: {admin.username}")
    print("Password: admin123")

db.close()