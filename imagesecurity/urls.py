"""ImageSecurityUsingEncryptionAndStitching URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path

from . import views

urlpatterns = [
    path('adminhome/',views.adminhome),
    path('clienthome/',views.clienthome),

    path('login/',views.login_post),

    # path('creg/',views.creg),

    path('auser/',views.auser),
    path('acomplaint/',views.acomplaint),
    path('',views.home),
    path('afeedback/',views.afeedback),
    
    path('api/creg/',views.creg),
    path('api/editcreg/',views.editcreg),

    path('api/userlogin/',views.ulog),

    path('api/viewuser',views.cuser),
    path('api/sendreq',views.sendreq),
    path('api/viewreq',views.viewreq),
    path('api/reqaccept',views.reqaccept),
    path('api/reqreject',views.reqreject),
    path('api/viewfriends',views.viewfriends),
    path('api/sendimage',views.imagechat),
    path('api/viewcomplaint',views.viewcomplaint),
    path('api/sendcomplaint',views.sendcomplaint),
    path('api/userprofile',views.userprofile),
    path('api/sendfeedback',views.sendfeedback),
    path('api/viewfeedback',views.viewfeedback),
    path('api/getstitched/<int:sid>/<int:rid>', views.retrieve_and_stitch, name='getstitched'),
    path('api/getencrypted/<int:sid>/<int:rid>', views.get_encrypted_images),
    path('api/getmessages/<int:sid>/<int:rid>', views.get_messages),
path('api/decrypt/<int:sid>/<int:rid>/<int:mid>', views.decrypt_image),



    
]
