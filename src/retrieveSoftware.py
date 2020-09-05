# http://api.oric.org/0.2/softwares/

import json
import pycurl
import zipfile
import os, sys
from io import BytesIO 
import pathlib

from shutil import copyfile


dest="build/usr/share/basic"
destetc="build/etc/basic/"
#exist_ok=True
#pathlib.Path(dest).mkdir(parents=True)


b_obj = BytesIO() 
crl = pycurl.Curl() 

# Set URL value
crl.setopt(crl.URL, 'http://api.oric.org/0.2/softwares/')

# Write bytes that are utf-8 encoded
crl.setopt(crl.WRITEDATA, b_obj)

# Perform a file transfer 
crl.perform() 

# End curl session
crl.close()

# Get the content stored in the BytesIO object (in byte characters) 
get_body = b_obj.getvalue()

# Decode the bytes stored in get_body to HTML and print the result 
#print('Output of GET request:\n%s' % get_body.decode('utf8')) 

datastore = json.loads(get_body.decode('utf8'))

for i in range(len(datastore)):
    print(i)
    #Use the new datastore datastructure
    tapefile=datastore[i]["download_software"]
    rombasic11=datastore[i]["basic11_ROM_TWILIGHTE"]
    up_joy=datastore[i]["up_joy"]
    down_joy=datastore[i]["down_joy"]
    right_joy=datastore[i]["right_joy"]
    left_joy=datastore[i]["up_joy"]
    fire1_joy=datastore[i]["fire1_joy"]
    fire2_joy=datastore[i]["fire2_joy"]    
    print(datastore[i])
    print(tapefile)
    if tapefile!="":
        b_obj_tape = BytesIO() 
        crl_tape = pycurl.Curl() 

        # Set URL value
        crl_tape.setopt(crl_tape.URL, 'https://cdn.oric.org//games/software/'+tapefile)
        crl_tape.setopt(crl_tape.SSL_VERIFYHOST, 0)
        crl_tape.setopt(crl_tape.SSL_VERIFYPEER, 0)
        # Write bytes that are utf-8 encoded
        crl_tape.setopt(crl_tape.WRITEDATA, b_obj_tape)

        # Perform a file transfer 
        crl_tape.perform() 

        # End curl session
        crl_tape.close()

        # Get the content stored in the BytesIO object (in byte characters) 
        get_body_tape = b_obj_tape.getvalue()

        # Decode the bytes stored in get_body to HTML and print the result 
        #print('Output of GET request:\n%s' % get_body.decode('utf8')) 

        extension=tapefile[-3:]


        head, tail = os.path.split(tapefile)

        f = open("build"+"/"+tail, "wb")
        f.write(get_body_tape)
        f.close()
        #tail=tail.lower()
        letter=tail[0:1].lower()
        folder=dest+'/'+letter
        print(folder)
        directory = os.path.dirname(folder)
        if not os.path.exists(folder):
            os.mkdir(folder)
            print("######################## Create "+directory)

        if extension=="zip":
            print("zip")
            with zipfile.ZipFile("build/"+tail, 'r') as zip_ref:
                zip_ref.extractall(dest+"/"+rombasic11+"/"+letter+"")
        if extension=="tap":
            print("tap")
            print("build/"+tail,dest+"/"+letter+"/"+tail.lower())
            copyfile("build/"+tail,dest+"/"+rombasic11+"/"+letter+"/"+tail.lower() )
        if not os.path.exists(destetc+"/"+letter):
            os.mkdir(destetc+"/"+letter)
        tcnf=tail.lower().split('.')
        cnf=tcnf[0]+".cnf"

        f = open(destetc+"/"+letter+"/"+cnf, "w")
        f.write("rom="+rombasic11+"\n")
        f.write("up="+up_joy+"\n")
        f.write("down="+down_joy+"\n")
        f.write("right="+right_joy+"\n")
        f.write("left="+left_joy+"\n")
        f.write("fire1="+fire1_joy+"\n")
        f.write("fire2="+fire2_joy+"\n")        
        f.close() 

        exit
