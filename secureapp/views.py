from django.shortcuts import render

# Create your views here.
def send_mail(request):
    try:





        # Get related ORM objects
        try:
            bidding_obj = Bidding.objects.get(id=winner_bid["bidding_id"])
        except Bidding.DoesNotExist:
            bidding_obj = None

        try:
            user_obj = UserReg.objects.get(id=winner_bid["userReg_id"])
        except UserReg.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'User not found in database'})

        email = user_obj.email

        # Send email
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()
            server.login("trainingstarted@gmail.com", "nlxasujxgazlbmgz")  # App password

            subject = "Bidding Result - You are the Winner!"
            fish_name = bidding_obj.fish.fish_name if bidding_obj and bidding_obj.fish else "your fish"
            body = f"Congratulations! You have won the bidding for fish: {fish_name}."
            message = f"Subject: {subject}\n\n{body}"

            server.sendmail("trainingstarted@gmail.com", email, message)
            server.quit()
