"""
This is a class for the authentication page for flutter. This class will allow users to create an
account with Playm8 and register them inside the database with a data created in the library table,
user table, authentication table, and the role table. This will initialize users and prepare them to
log into the wonderful world of PlayM8 :)
"""
from play_m8DB import supabase
from postgrest.exceptions import APIError
from supabase_auth.errors import AuthApiError
class Account:
    #initializer for methods
    def __init__(self):
        pass

    #Creates an account in supabase
    def createAccount(self,username,email,password):
        response = supabase.auth.sign_up(
            {"email" : email,
             "password" : password
             })
        self.addUser(response.user.id,username)
    @staticmethod
    #Helper function for the addUser function is used to add a library
    def addLibrary(user):
        #initializing library
        library=None
        try:
            library=supabase.table("library").insert({"user_id": user}).execute()
            return library.data[0]["libraryid"]
        except APIError as e:
            print("This already exists!!!")

    @staticmethod
    def addRole():
        #initializing library
        role=None
        try:
            role=supabase.table("roles").insert({"rolename": "Regular"}).execute()
            return role.data[0]["roleid"]
        except APIError as e:
            print(e)

    #Helper function for createAccount to add a new user
    def addUser(self,user, username):
        supabase.table("users").insert({"userID": user, "username": username}).execute()
        library=self.addLibrary(user)
        supabase.table("users").update({"lib": library}).eq("userID",user).execute()

#New changes from Xavion
    def signIn (self,email,password):
        from user import User
        #Throws an exception if there is no account to sign into
        session=None
        try:
            session = supabase.auth.sign_in_with_password(
                {"email" : email,
                 "password" : password
                 })
            username=supabase.table("users").select("username").eq("userID",session.user.id).execute().data[0]["username"]
            #Will return a user to be used at the end for user function calls later
            return User(session.user.id,email,username)
        except AuthApiError as ae:
            print(ae)
    """
    Things need to be worked on for finishing touches
    def validate_email(self):
    def validate_password(self):
    def validate_username(self):
    """

#Used for testing of class main functions
if __name__ =="__main__":

    #Inputs recieved from front end
    username: str=input("Please enter a nice username: ")
    email: str= input("\nPlease enter your email here: ")
    password: str= input("\nPlease enter your new password: ")

    ac=Account()
    #Inputs will be recieved from frontend
    ac.createAccount(username,email,password)
    wait=input("Did you confirm?")
    ac.signIn(email,password)
    supabase.auth.sign_out()
