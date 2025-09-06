import json
import math
import os
import random
import smtplib
from django.db.models import Q
from datetime import datetime
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render
from django.contrib.auth import authenticate, login
from django.contrib.auth.models import User, Group
from django.core.files.storage import FileSystemStorage
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone
from .utils import partition_image, stitch_image, generate_key_sequence, encrypt_image_part, decrypt_image_part

from django.conf import settings

from . models import *
#Admin
# Create your views here.
def login_post(request):
    if 'submit' in request.POST:
        u=request.POST['uname']
        p=request.POST['pwd']
        l=authenticate(username=u, password=p)
        login(request, l)
        if l.groups.filter(name='Admin').exists():
            return HttpResponse('<script>alert("Logged in as admin"); window.location="/adminhome"</script>')
        elif l.groups.filter(name='Client').exists():
            request.session['clid']=l.id #login id
            c=Registration.objects.get(user_id=l.id)
            request.session['cid']=c.id #user id
            return HttpResponse('<script>alert("Logged in as client"); window.location="/clienthome"</script>')
    return render(request,'login.html')

def home(request):
    return render(request,'Bell/index.html')

def adminhome(request):
    return render(request,'Admin/home.html')

def clienthome(request):
    return render(request,'Client/home.html')

def auser(request):
    u=Registration.objects.all()
    return render(request,'Admin/user.html',{'u':u})

def acomplaint(request):
    u=Complaint.objects.all()
    if 'submit' in request.POST:
        r = request.POST['reply']
        id = request.POST['id']
        q=Complaint.objects.get(id=id)
        q.reply=r
        q.save()
        return HttpResponse('<script>alert("Reply send successfully"); window.location="/acomplaint"</script>')

    return render(request,'Admin/complaint.html',{'u':u})

def afeedback(request):
    u=Feedback.objects.all()
    return render(request,'Admin/feedback.html',{'u':u})

#Client

def clienthome(request):
    return render(request,'Client/home.html')

def creg(request):
        username = request.POST['uname']
        pwd=request.POST['pwd']
        fname = request.POST['fname']
        lname = request.POST['lname']
        email = request.POST['email']
        phone = request.POST['phone']
        image = request.FILES.get('image')
        fs=FileSystemStorage()
        saved_path=fs.save(image.name,image)

        u=User.objects.create(username=username, password=make_password(pwd))
        u.groups.add(Group.objects.get(name='Client'))
        c=Registration(
            fname=fname,
            lname=lname,
            email=email,
            phone=phone,
            photo=saved_path,
            user_id=u.id)
        c.save()
        return render(request,'Client/reg.html')

def editcreg(request):
        uid = request.POST['uid']
        h=Registration.objects.get(user_id=uid)
        h.fname = request.POST['fname']
        h.lname = request.POST['lname']
        h.email = request.POST['email']
        h.phone = request.POST['phone']
        try:
            image = request.FILES.get('image')
            fs=FileSystemStorage()
            saved_path=fs.save(image.name,image)
            h.photo=saved_path
        except:
            pass
        h.save()
        return render(request,'Client/reg.html')


def cuser(request):
    u=Registration.objects.all()
    return render(request,'Admin/feedback.html',{'u':u})

def cfriendrequest(request):
    u=FriendRequest.objects.all()
    return render(request,'Admin/feedback.html',{'u':u})


# def clienthome(request):
#     return render(request,'Client/home.html')

#Flutter Side
def ulog(request):
    uname=request.POST.get('uname')
    pwd=request.POST.get('pwd')
    l=authenticate(username=uname, password=pwd)
    t=Registration.objects.get(user_id=l.id)
    
    if l is not None:
        login(request, l)
        email = t.email

        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login("trainingstarted@gmail.com", "nlxasujxgazlbmgz")  # App password

        r=random.randint(1,10000)
    

        subject = "Verify User"
        body = f"Your Onetime Password is: {r}"
        message = f"Subject: {subject}\n\n{body}"
        server.sendmail("trainingstarted@gmail.com", email, message)
        server.quit()
        response = {
        'uid':l.id,
        'status':'success',
        'img':t.photo.name,
        'name':t.fname + ' ' + t.lname,
    }
    else:
        response = {
        'uid':None,
        'status':'fail'
    }
    return JsonResponse(response)

def cuser(request):
    uid=request.POST.get('uid')
    data=[]
    u=Registration.objects.all()
    print(uid)
    for i in u:

     if i.user_id == int(uid):
        pass
     else:
        print('sender:',uid,'reciever:',i.user.pk, )

        try:
            r=FriendRequest.objects.get(sender_id=uid, receiver_id=i.user.pk)
            if(r.status=='pending'):
                a='Requested'
            if(r.status=='accepted'):
                a='Friend'
            if(r.status=='rejected'):
                a='Rejected Your Request'
            data.append({
                'id':i.pk,
                'n':i.fname+i.lname,
                'e':i.email,
                'p':i.phone,
                'image':i.photo.name,
                'button':a,
            })
        except:
                data.append({
                'id':i.pk,
                'n':i.fname+i.lname,
                'e':i.email,
                'p':i.phone,
                'image':i.photo.name,
                'button':'Send request'
            })        
        print(data)
    responce ={
        'data':data
    }
    return JsonResponse(responce)

def sendreq(request):
    uid=request.POST.get('uid')
    fid=request.POST.get('fid')
    print(uid,fid,'iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii')
    ru=Registration.objects.get(id=fid)
    f=FriendRequest(date=timezone.now(), status='pending',receiver_id=ru.user_id, sender_id=uid)
    f.save()
    response ={
        'message': 'request send'
    }
    return JsonResponse(response)

def viewreq(request):
    data=[]
    ui=request.POST.get('uid')
    print(ui)
    o=FriendRequest.objects.filter(receiver_id=ui, status='pending')
    for u in o:
        i=Registration.objects.get(user=u.sender)
        if u.status=='pending':
         data.append({
            'id':i.user.pk,
            'n':i.fname+i.lname,
            'e':i.email,
            'p':i.phone,
            'image':i.photo.name,
        })
    responce ={
        'data': data
    }
    print(data)
    return JsonResponse(responce)

def reqaccept(request):
    uid=request.POST.get('uid')
    fid=request.POST.get('fid')
    print(uid,fid,'iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii')
    s=FriendRequest.objects.get(receiver_id=uid, sender_id=fid)
    s.status='accepted'
    s.save()

    responce ={
        'data': 'request accepted'
    }
    return JsonResponse(responce)

def reqreject(request):
    uid=request.POST.get('uid')
    fid=request.POST.get('fid')
    s=FriendRequest.objects.get(receiver_id=uid, sender_id=fid)
    s.status='rejected'
    s.save()

    responce ={
        'data': 'request rejected'
    }
    return JsonResponse(responce)

def viewfriends(request):
    data = []
    uid = request.POST.get('uid')
    print("Current User ID:", uid)

    # Get all accepted friend requests where the user is sender or receiver
    friends = FriendRequest.objects.filter(
        Q(receiver_id=uid) | Q(sender_id=uid),
        status='accepted'
    )

    for f in friends:
        # Find the other user (friend)
        if str(f.sender.pk) == str(uid):
            friend_user = f.receiver
        else:
            friend_user = f.sender

        # Get registration details of the friend
        reg = Registration.objects.get(user=friend_user)
        data.append({
            'id': reg.user.pk,
            'n': f"{reg.fname} {reg.lname}",
            'e': reg.email,
            'ph': reg.phone,
            'image': reg.photo.name if reg.photo else None,
            'friend_since': f.updated_at.strftime('%Y-%m-%d') if hasattr(f, 'updated_at') else None
        })

    response = {'data': data}
    print("Friends List:", data)
    return JsonResponse(response)


def viewcomplaint(request):
    data=[]
    uid=request.POST.get('uid')
    r=Registration.objects.get(user_id=uid)
    o=Complaint.objects.filter(registration_id=r.pk)
    for u in o:
        data.append({
            'id':u.pk,
            'c':u.complaint,
            'r':u.reply,
            'd':u.date,
            's':u.status,
        })
    responce ={
        'data': data
    }
    print(data)
    return JsonResponse(responce)

def sendcomplaint(request):
    uid=request.POST.get('uid')
    c=request.POST.get('complaint')

    r=Registration.objects.get(user_id=uid)
    o=Complaint(complaint=c,registration_id=r.pk, reply='pending', date=timezone.now(), status='demo')
    o.save()
   
    responce ={
        'data': 'complaint send'
    }
    return JsonResponse(responce)


def viewfeedback(request):
    data=[]
    uid=request.POST.get('uid')
    r=Registration.objects.get(user_id=uid)
    o=Feedback.objects.all()
    for u in o:
        q=Registration.objects.get(id=u.registration.pk)

        data.append({
            'id':u.pk,
            'c':u.feedback,
            'n':u.registration.fname + u.registration.lname,
            'd':u.date,
            'image':q.photo.name,
        })
    responce ={
        'data': data
    }
    print(data)
    return JsonResponse(responce)

def sendfeedback(request):
    uid=request.POST.get('uid')
    c=request.POST.get('feedback')

    r=Registration.objects.get(user_id=uid)
    o=Feedback(feedback=c,registration_id=r.pk, date=timezone.now())
    o.save()
   
    responce ={
        'data': 'complaint send'
    }
    return JsonResponse(responce)


def userprofile(request):
    uid=request.POST.get('uid')
    data=[]
    r= Registration.objects.get(user_id=uid)
    data.append({
        'fn':r.fname,
        'ln':r.lname,
        'ph':r.phone,
        'e':r.email,
        'photo':r.photo.name,
    })

    responce ={
        'data': data
    }
    return JsonResponse(responce)


# def imagechat(request):
#     sid=request.POST.get('sid')
#     rid=request.POST.get('rid')
#     img=request.FILES.get('image')
#     fs=FileSystemStorage()
#     saved_path=fs.save(img.name,img)
#     i=Image(image=saved_path,date=timezone.now(),receiver_id=rid,sender_id=sid)
#     i.save()
#     responce ={
#         'status': 'success'
#     }
#     return JsonResponse(responce)
import cv2
import numpy as np
from django.core.files.storage import FileSystemStorage
from django.utils import timezone
from django.http import JsonResponse, HttpResponse
from .models import ImageModel
from .utils import partition_image, stitch_image, generate_key_sequence, encrypt_image_part, decrypt_image_part



import os, base64, io, math
import cv2
import numpy as np
from django.core.files.storage import FileSystemStorage
from django.utils import timezone
from django.http import JsonResponse
from django.conf import settings
from Crypto.Cipher import AES
from PIL import Image
from .models import ImageModel  # <-- Updated to use ImageModel


# ---------- ENCRYPT & STORE ----------
def imagechat(request):
    sid = request.POST.get('sid')
    rid = request.POST.get('rid')
    img = request.FILES.get('image')
    fs = FileSystemStorage()

    # Determine new message_id
    total_count = ImageModel.objects.count()

# Next message_id will be count + 1
    next_message_id = total_count + 1

    # Save original image (not encrypted)
    saved_path = fs.save(img.name, img)
    full_path = fs.path(saved_path)
    ImageModel.objects.create(
        sender_id=sid,
        receiver_id=rid,
        image=saved_path,
        part_index=-1,
        key=None,
        message_id=next_message_id,
        date=timezone.now()
    )

    # Partition + Encrypt
    original_img = cv2.imread(full_path)
    parts = partition_image(original_img, rows=2, cols=2)

    for idx, part in enumerate(parts):
        # AES Key
        key = os.urandom(16)
        cipher = AES.new(key, AES.MODE_EAX)
        encrypted_data, tag = cipher.encrypt_and_digest(cv2.imencode('.jpg', part)[1].tobytes())
        encrypted_blob = cipher.nonce + encrypted_data

        enc_filename = f"enc_{next_message_id}_{idx}_{img.name}"
        enc_full_path = fs.path(enc_filename)
        with open(enc_full_path, 'wb') as f:
            f.write(encrypted_blob)

        ImageModel.objects.create(
            sender_id=sid,
            receiver_id=rid,
            image=enc_filename,
            part_index=idx,
            key=base64.b64encode(key).decode(),
            message_id=next_message_id,
            date=timezone.now()
        )

    return JsonResponse({
        'status': 'success',
        'original_image': fs.url(saved_path),
        'message_id': next_message_id,
        'message': 'Image encrypted and saved.'
    })


# ---------- GET MESSAGES ----------
def get_messages(request, sid, rid):
    fs = FileSystemStorage()
    msgs = ImageModel.objects.filter(
        sender_id__in=[sid, rid],
        receiver_id__in=[sid, rid]
    ).order_by('date')

    data = []
    for m in msgs:
        # If it's encrypted (part of a stitched image), DO NOT send real image
        if m.part_index != -1:
            image_url = None  # Hide actual encrypted images
        else:
            image_url = fs.url(m.image.name)  # Show only normal (non-encrypted) images

        data.append({
            'id': m.id,
            'sender_id': m.sender_id,
            'receiver_id': m.receiver_id,
            'is_sender': str(m.sender_id) == str(sid),
            'image_url': image_url,
            'part_index': m.part_index,
            'key_seed': m.key,
            'message_id': m.message_id
        })

    return JsonResponse({'status': 'success', 'messages': data})




# ---------- DECRYPT & STITCH ----------
def decrypt_image(request, sid, rid, mid):
    parts = list(ImageModel.objects.filter(
        sender_id=sid, receiver_id=rid, message_id=mid, part_index__gte=0
    ).order_by('part_index'))

    print("DEBUG: Parts fetched:", [p.id for p in parts])

    if not parts:
        return JsonResponse({"status": "error", "message": "No parts found"})

    decrypted_images = []
    for p in parts:
        try:
            print(f"Decrypting part {p.part_index} (ID: {p.id}) with key: {p.key}")
            file_path = p.image.path
            with open(file_path, "rb") as f:
                encrypted_data = f.read()
            key = base64.b64decode(p.key)
            cipher = AES.new(key, AES.MODE_EAX, nonce=encrypted_data[:16])
            decrypted_data = cipher.decrypt(encrypted_data[16:])
            img = Image.open(io.BytesIO(decrypted_data)).convert("RGB")
            decrypted_images.append(img)
        except Exception as e:
            print(f"Decryption failed for part {p.id}: {e}")

    if not decrypted_images:
        return JsonResponse({"status": "error", "message": "Failed to decrypt parts"})

    # Resize to smallest
    min_w = min(img.width for img in decrypted_images)
    min_h = min(img.height for img in decrypted_images)
    resized = [img.resize((min_w, min_h)) for img in decrypted_images]

    # Determine grid (2x2)
    rows, cols = 2, 2
    stitched = Image.new("RGB", (cols * min_w, rows * min_h))
    for idx, img in enumerate(resized):
        x = (idx % cols) * min_w
        y = (idx // cols) * min_h
        stitched.paste(img, (x, y))

    # Save stitched image
    stitched_dir = os.path.join(settings.MEDIA_ROOT, "stitched")
    os.makedirs(stitched_dir, exist_ok=True)
    stitched_path = os.path.join(stitched_dir, f"stitched_{sid}_{rid}_{mid}.jpg")
    stitched.save(stitched_path)

    stitched_url = f"{settings.MEDIA_URL}stitched/stitched_{sid}_{rid}_{mid}.jpg"
    return JsonResponse({"status": "success", "stitched_image": stitched_url})
# ----- Get Encrypted Parts -----
def get_encrypted_images(request, sid, rid):
    fs = FileSystemStorage()
    parts = ImageModel.objects.filter(sender_id=sid, receiver_id=rid, part_index__gte=0).order_by('part_index')
    return JsonResponse({
        'status': 'success',
        'encrypted_parts': [fs.url(p.image.name) for p in parts]
    })


# ----- Decrypt & Stitch -----
def retrieve_and_stitch(request, sid, rid):
    fs = FileSystemStorage()
    parts_objs = ImageModel.objects.filter(sender_id=sid, receiver_id=rid, part_index__gte=0).order_by('part_index')
    if not parts_objs.exists():
        return JsonResponse({'status': 'error', 'message': 'No images found'})
    
    decrypted_parts = []
    for obj in parts_objs:
        part_path = fs.path(obj.image.name)
        encrypted_part = cv2.imread(part_path)
        key = np.array(json.loads(obj.key), dtype=np.uint8)  # load stored key
        decrypted = decrypt_image_part(encrypted_part, key)
        decrypted_parts.append(decrypted)
    
    stitched_image = stitch_image(decrypted_parts, rows=2, cols=2)
    stitched_filename = f"stitched_{sid}_{rid}.jpg"
    stitched_path = fs.path(stitched_filename)
    cv2.imwrite(stitched_path, stitched_image)
    return JsonResponse({'status': 'success', 'stitched_image': fs.url(stitched_filename)})



