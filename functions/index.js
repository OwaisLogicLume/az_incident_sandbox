  /**
   * Import function triggers from their respective submodules:
   *
   * const {onCall} = require("firebase-functions/v2/https");
   * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
   *
   * See a full list of supported triggers at https://firebase.google.com/docs/functions
   */

  const { onRequest } = require("firebase-functions/v2/https");
  const logger = require("firebase-functions/logger");

  const functions = require("firebase-functions");
  const admin = require("firebase-admin");
  const axios = require("axios");

  const { decode } = require("html-entities");
  const { Message } = require("firebase-functions/v1/pubsub");
  // const entities = new AllHtmlEntities();

  admin.initializeApp();

  const firestore = admin.firestore();

  function getAvailableUnitsAlphanumerics(units) {
    //   let unescapedString = decode(units || "");

    //   let regex = /\d+/g;
    //   let matches = unescapedString.match(regex);

    let unitsWithLables = units.split(" ").map((e) => decode(e || ""));
    logger.log("unitsWithLables => ", unitsWithLables);

    let unitsAlphanumeric = [...unitsWithLables.map((e) => e.split(":")[0])];
    logger.log("available stations => ", unitsAlphanumeric);

    return new Set(unitsAlphanumeric);
  }

  /**
   * Check if an incident unit matches any of the user's subscribed stations
   * Supports both exact matching (E191) and wildcard matching (BC*, E1*)
   * @param {string} incidentUnit - The unit from the incident (e.g., "BC5")
   * @param {Array<string>} userStations - User's subscribed stations (may include wildcards)
   * @returns {boolean} - True if there's a match
   */
  function matchesUserStation(incidentUnit, userStations) {
    for (const station of userStations) {
      if (station.endsWith('*')) {
        // Wildcard matching
        const prefix = station.slice(0, -1);
        if (incidentUnit.startsWith(prefix)) {
          return true;
        }
      } else {
        // Exact matching
        if (incidentUnit === station) {
          return true;
        }
      }
    }
    return false;
  }

  // API URLs
  const PHOENIX_FIRE_API = "https://maps.phoenix.gov/phxfire/rest/services/Active_Incidents__Public/MapServer/0/query?f=json&cacheHint=true&resultOffset=0&resultRecordCount=100&where=1%3D1&orderByFields=Incident%20DESC&outFields=*&returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPoint";
  const PHXSDR_API = "https://api.phxsdr.com/api/incidents";

  // Helper function to fetch from a specific API
  async function fetchFromAPI(apiUrl, apiName) {
    try {
      logger.log(`🔄 Fetching from ${apiName}...`);
      const response = await axios.get(apiUrl, { timeout: 25000 });

      if (response?.data?.error?.code == 500) {
        logger.log(`❌ ${apiName}: API error 500`);
        return [];
      }

      const features = response?.data?.features || [];
      logger.log(`✅ ${apiName}: ${features.length} incidents`);
      return features;
    } catch (error) {
      logger.error(`⚠️ ${apiName} error:`, error.message);
      return [];
    }
  }

  exports.notifyUsers = functions.pubsub
    .schedule("every 1 minutes")
    .onRun(async (message) => {
      try {
        logger.log('═══════════════════════════════════');
        logger.log('🚨 FETCHING FROM BOTH APIS');
        logger.log('═══════════════════════════════════');

        // Fetch from both APIs in parallel
        const [phoenixFeatures, phxsdrFeatures] = await Promise.all([
          fetchFromAPI(PHOENIX_FIRE_API, 'Phoenix Fire'),
          fetchFromAPI(PHXSDR_API, 'phxsdr')
        ]);

        // Merge and deduplicate incidents by Incident ID
        const allFeatures = [...phoenixFeatures, ...phxsdrFeatures];
        const uniqueIncidentsMap = new Map();

        for (const feature of allFeatures) {
          const incidentId = feature.attributes?.Incident;
          if (incidentId && !uniqueIncidentsMap.has(incidentId)) {
            uniqueIncidentsMap.set(incidentId, feature);
          }
        }

        logger.log(`📊 Total unique incidents: ${uniqueIncidentsMap.size}`);

        // Convert merged incidents to notification format
        const incidents = Array.from(uniqueIncidentsMap.values()).map((feature) => ({
          id: feature.attributes.Incident,
          stations: getAvailableUnitsAlphanumerics(feature.attributes.Units),
          genLocInfo: feature.attributes.GenLocInfo,
        }));

        const usersSnapshot = await firestore.collection("users").get();
        const users = usersSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        for (const user of users) {
          const filteredIncidents = incidents
            ?.filter(
              (incident) =>
                !user.alerted_incidents.includes(incident.id) &&
                Array.from(incident.stations).some((incidentUnit) =>
                  matchesUserStation(incidentUnit, user.stations)
                )
            )
            .map((incident) => ({
              ...incident,
              alertStations: Array.from(incident.stations).filter((incidentUnit) =>
                matchesUserStation(incidentUnit, user.stations)
              ),
            }));

          if (filteredIncidents.length > 0) {
            //   const incidentIds = filteredIncidents.map((incident) => incident.id);
            //   const alertStations = filteredIncidents.map(
            //     (incident) => incident.alertStations
            //   );

            for (let incident of filteredIncidents) {
              logger.log(
                "incident.alertStations - to be in notification => ",
                incident.alertStations
              );

              const payload = {
                token: user.fcm,
                
                notification: {
                  title: "New Incident Alert",
                  body: `${incident.alertStations?.join(", ")} ${
                    incident.alertStations.length > 1 ? "have" : "has"
                  } been dispatched. ${incident.genLocInfo}`,
                },
                data: {
                  incident_id: JSON.stringify(incident),
                },
                android: {
                  notification: {
                    sound: "default",
                  },
                },
                apns: {
                  payload: {
                    aps: {
                      sound: "default",
                      badge: 0,
                    },
                  },
                },
              };

              try {
                logger.log("trying to send notification on fcm : ", user.fcm);
                await admin.messaging().send(payload);
                logger.log("Successfully sent message to:", user.fcm);

                await firestore
                  .collection("users")
                  .doc(user.id)
                  .update({
                    alerted_incidents: admin.firestore.FieldValue.arrayUnion(
                      incident.id
                    ),
                  });
              } catch (error) {
                logger.error("Error sending message to:", user.device_id, error);

                if (
                  error.code === "messaging/invalid-registration-token" ||
                  error.code === "messaging/registration-token-not-registered"
                ) {
                  await firestore.collection("users").doc(user.id).delete();
                  logger.log("Removed user with device ID:", user.device_id);
                  return;
                }
              }
            }

            //   const payload = {
            //     token: user.fcm,
            //     notification: {
            //       title: "New Incidents Alert",
            //       body: `Units ${alertStations.join(", ")} have been dispatched.`,
            //     },
            //     data: {
            //       incidents: JSON.stringify(filteredIncidents),
            //     },
            //     android: {
            //       notification: {
            //         sound: "default",
            //       },
            //     },
            //     apns: {
            //       payload: {
            //         aps: {
            //           sound: "default",
            //         },
            //       },
            //     },
            //   };
          }
        }
      } catch (error) {
        logger.error("Error fetching incidents or processing users:", error);
      }
    });
