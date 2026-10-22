import asyncio
import aiosqlite

async def migrate():
    async with aiosqlite.connect('craveguard.db') as db:
        async with db.execute("PRAGMA table_info(user_profiles)") as cursor:
            cols = [row[1] async for row in cursor]
        if 'onboarding_complete' not in cols:
            await db.execute('ALTER TABLE user_profiles ADD COLUMN onboarding_complete BOOLEAN DEFAULT 0')
            await db.commit()
            print('Added onboarding_complete column')
        else:
            print('Column already exists')
        async with db.execute("PRAGMA table_info(user_profiles)") as cursor:
            rows = [row async for row in cursor]
        for r in rows:
            print(r)

asyncio.run(migrate())
