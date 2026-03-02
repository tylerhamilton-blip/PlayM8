import os
from supabase import create_client, Client
from dotenv import load_dotenv
#Adding .environment file
load_dotenv()

#Getting the
supabase: Client = create_client(
    os.environ.get("SUPABASE_URL"),
    os.environ.get("SUPABASE_KEY")
)
