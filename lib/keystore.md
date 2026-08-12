password: 34r#Fith$
Name: Tanvir Ahmed



$ keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Enter keystore password:  

Re-enter new password: 

Enter the distinguished name. Provide a single dot (.) to leave a sub-component empty or press ENTER to use the default value in braces.
What is your first and last name?
  [Unknown]:  Tanvir Ahmed
What is the name of your organizational unit?
  [Unknown]:  Tanvir Ahmed
What is the name of your organization?
  [Unknown]:  Tanvir Ahmed
What is the name of your City or Locality?
  [Unknown]:  Dhaka
What is the name of your State or Province?
  [Unknown]:  Dhaka
What is the two-letter country code for this unit?
  [Unknown]:  BD
Is CN=Tanvir Ahmed, OU=Tanvir Ahmed, O=Tanvir Ahmed, L=Dhaka, ST=Dhaka, C=BD correct?
  [no]:  Yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
        for: CN=Tanvir Ahmed, OU=Tanvir Ahmed, O=Tanvir Ahmed, L=Dhaka, ST=Dhaka, C=BD
[Storing android/app/upload-keystore.jks]