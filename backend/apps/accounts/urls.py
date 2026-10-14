from django.urls import path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

router = DefaultRouter()
router.register("devices", views.DeviceTokenViewSet, basename="device")
router.register("invite-links", views.InviteLinkViewSet, basename="invite-link")

urlpatterns = [
    path("login/", views.LoginView.as_view(), name="login"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("logout/", views.LogoutView.as_view(), name="logout"),
    path("register/", views.RegisterView.as_view(), name="register"),
    path("invites/<str:code>/", views.InviteLookupView.as_view(), name="invite-lookup"),
    path("verify-email/send/", views.SendVerifyEmailView.as_view(), name="verify-email-send"),
    path("verify-email/confirm/", views.ConfirmEmailView.as_view(), name="verify-email-confirm"),
    path("password/forgot/", views.ForgotPasswordView.as_view(), name="password-forgot"),
    path("password/reset/", views.ResetPasswordView.as_view(), name="password-reset"),
    path("password/change/", views.ChangePasswordView.as_view(), name="password-change"),
    path("login-link/", views.LoginLinkView.as_view(), name="login-link"),
    path("login-link/confirm/", views.LoginLinkConfirmView.as_view(), name="login-link-confirm"),
    path("me/", views.MeView.as_view(), name="me"),
    path("me/onboarding-complete/", views.CompleteOnboardingView.as_view(), name="onboarding-complete"),
] + router.urls
