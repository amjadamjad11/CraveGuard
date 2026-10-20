"""Risk scoring algorithm for location-based trigger detection."""
import math
from typing import List, Dict


# Scoring weights — explainable and configurable
WEIGHTS = {
    "smoking_events_nearby": 0.4,
    "craving_events_nearby": 0.3,
    "visit_frequency": 0.1,
    "avg_craving_intensity": 0.2,
}

# Minimum evidence thresholds
MIN_TOTAL_EVENTS = 3  # At least 3 smoking/craving events to suggest
MIN_VISITS = 2         # At least 2 visits to the location
DISTANCE_THRESHOLD_METERS = 200  # Clustering distance


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance in meters between two lat/lon points."""
    R = 6371000  # Earth's radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def calculate_risk_score(
    smoking_events_nearby: int,
    craving_events_nearby: int,
    visit_count: int,
    avg_craving_intensity: float,
) -> dict:
    """Calculate risk score with explainable factors.

    Returns a dict with:
        - score (0.0-1.0)
        - level (high/medium/low/insufficient)
        - factors: list of explanations
    """
    total_events = smoking_events_nearby + craving_events_nearby

    if total_events < MIN_TOTAL_EVENTS:
        return {
            "score": 0.0,
            "level": "insufficient",
            "factors": [f"Insufficient evidence: only {total_events} events recorded (need at least {MIN_TOTAL_EVENTS})."],
        }

    # Normalize factors to 0-1 range
    smoking_score = min(1.0, smoking_events_nearby / 10.0)
    craving_score = min(1.0, craving_events_nearby / 10.0)
    visit_score = min(1.0, visit_count / 20.0)
    intensity_score = min(1.0, avg_craving_intensity / 10.0)

    # Weighted sum
    score = (
        WEIGHTS["smoking_events_nearby"] * smoking_score
        + WEIGHTS["craving_events_nearby"] * craving_score
        + WEIGHTS["visit_frequency"] * visit_score
        + WEIGHTS["avg_craving_intensity"] * intensity_score
    )

    # Determine level
    if score >= 0.7:
        level = "high"
    elif score >= 0.4:
        level = "medium"
    else:
        level = "low"

    # Build explanation factors
    factors = []
    if smoking_events_nearby > 0:
        factors.append(f"You've smoked near this location {smoking_events_nearby} time(s).")
    if craving_events_nearby > 0:
        factors.append(f"You've experienced cravings here {craving_events_nearby} time(s).")
    if avg_craving_intensity >= 7:
        factors.append(f"Average craving intensity here is high ({avg_craving_intensity:.1f}/10).")
    if visit_count > 5:
        factors.append(f"You visit this area frequently ({visit_count} visits).")

    return {"score": round(score, 3), "level": level, "factors": factors}


def cluster_events(events: List[Dict], distance_threshold: float = DISTANCE_THRESHOLD_METERS) -> List[Dict]:
    """Cluster location events into approximate places.

    Each event dict needs: latitude, longitude, type (smoking/craving), intensity (optional)
    Returns clusters with centroid and event counts.
    """
    if not events:
        return []

    clusters = []

    for event in events:
        if event.get("latitude") is None or event.get("longitude") is None:
            continue

        matched = False
        for cluster in clusters:
            dist = haversine_distance(
                cluster["latitude"], cluster["longitude"],
                event["latitude"], event["longitude"],
            )
            if dist <= distance_threshold:
                # Update cluster
                n = cluster["visit_count"]
                cluster["latitude"] = (cluster["latitude"] * n + event["latitude"]) / (n + 1)
                cluster["longitude"] = (cluster["longitude"] * n + event["longitude"]) / (n + 1)
                cluster["visit_count"] += 1
                if event.get("type") == "smoking":
                    cluster["smoking_events"] += 1
                elif event.get("type") == "craving":
                    cluster["craving_events"] += 1
                    if event.get("intensity"):
                        intensities = cluster.get("_intensities", [])
                        intensities.append(event["intensity"])
                        cluster["_intensities"] = intensities
                        cluster["avg_intensity"] = sum(intensities) / len(intensities)
                matched = True
                break

        if not matched:
            new_cluster = {
                "latitude": event["latitude"],
                "longitude": event["longitude"],
                "visit_count": 1,
                "smoking_events": 1 if event.get("type") == "smoking" else 0,
                "craving_events": 1 if event.get("type") == "craving" else 0,
                "avg_intensity": event.get("intensity", 0),
                "_intensities": [event["intensity"]] if event.get("intensity") else [],
            }
            clusters.append(new_cluster)

    # Score each cluster
    results = []
    for cluster in clusters:
        score_data = calculate_risk_score(
            cluster["smoking_events"],
            cluster["craving_events"],
            cluster["visit_count"],
            cluster["avg_intensity"],
        )
        if score_data["level"] != "insufficient":
            results.append({
                "latitude": round(cluster["latitude"], 6),
                "longitude": round(cluster["longitude"], 6),
                "visit_count": cluster["visit_count"],
                "smoking_events_nearby": cluster["smoking_events"],
                "craving_events_nearby": cluster["craving_events"],
                "avg_craving_intensity": round(cluster["avg_intensity"], 1),
                "risk_score": score_data["score"],
                "risk_level": score_data["level"],
                "factors": score_data["factors"],
            })

    return sorted(results, key=lambda x: x["risk_score"], reverse=True)
