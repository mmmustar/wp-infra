from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    # Simule un temps de réflexion entre 2 et 5 secondes
    wait_time = between(2, 5)

    @task
    def index(self):
        # Timeout étendu à 15 secondes pour laisser plus de temps à la réponse
        with self.client.get("/", catch_response=True, timeout=15) as response:
            # Si la réponse prend 15 secondes ou plus, on la considère comme un timeout
            if response.elapsed.total_seconds() >= 15:
                response.failure("Timeout dépassé (>=15 secondes)")
            elif response.status_code != 200:
                response.failure(f"Statut non attendu: {response.status_code}")
