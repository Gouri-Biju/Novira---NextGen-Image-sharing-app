from django.db import models
from django.contrib.auth.models import User

class Registration(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    fname = models.CharField(max_length=100)
    lname = models.CharField(max_length=100)
    photo = models.ImageField()
    email = models.EmailField()
    phone = models.CharField(max_length=15)

class Complaint(models.Model):
    registration = models.ForeignKey(Registration, on_delete=models.CASCADE)
    complaint = models.TextField()
    reply = models.CharField(max_length=100)
    date = models.DateTimeField()
    status = models.CharField(max_length=20)

class Feedback(models.Model):
    registration = models.ForeignKey(Registration, on_delete=models.CASCADE)
    feedback = models.TextField()
    date = models.DateTimeField()

class FriendRequest(models.Model):
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_requests_sent')
    receiver = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_requests_received')
    date = models.DateTimeField()
    status = models.CharField(max_length=20)

class Image(models.Model):
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='images_sent')
    receiver = models.ForeignKey(User, on_delete=models.CASCADE, related_name='images_received')
    image = models.ImageField()
    date = models.DateTimeField()
