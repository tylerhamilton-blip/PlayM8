from play_m8DB import supabase
from postgrest.exceptions import APIError
from supabase_auth.errors import AuthApiError
from account import Account
class User:
    #Construction for user class
    def __init__(self,user_id,email,username):
        self.__user_id=user_id
        self.__username=username
        self.__email=email

    def __repr__(self):
        return "Hello "+ self.__username

    #Function is used to delete a users account from the database
    #Before using this function please confirm in the frontend that you want to delete the data
    #ONCE THE FUNCTION RUNS THE DATA WILL BE
    def deleteAccount(self):
        supabase.auth.delete_user()

    #User has the option to sign up with us again however with a different email
    #Can be one of the last things we implement not needed
    #def makeAccount(self):
    @property
    #Getters
    def getUserId(self):
        return self.__user_id
    def getUsername(self):
        return self.__username
    def getEmail(self):
        return self.__email
    #Setters
    #Work in progress
    def setEmail(self,email:str):
        try:
            if email.count("@")==1 and (email[0]!=" " and email[0]!="@"):
                supabase.auth.update_user({"email":email})
                self.__email=email
        except AuthApiError as ape:
            print(ape)

    #Work on for the next sprints
    def setPassword(self,password):
        #Maybe add a constraint later
        print("hi") #Stub

    #Work on for the next sprints
    def setUsername(self):
        #Maybe add a constraint later
        print("hi") #Stub
