  /**
   * Import function triggers from their respective submodules:
   *
   * const {onCall} = require("firebase-functions/v2/https");
   * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
   *
   * See a full list of supported triggers at https://firebase.google.com/docs/functions
   */

  const { onRequest } = require("firebase-functions/v2`/https");
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

  // URL : https://maps.phoenix.gov/phxfire/rest/services/Active_Incidents__Public/MapServer/0/query?f=json&cacheHint=true&resultOffset=0&resultRecordCount=100&where=1%3D1&orderByFields=Incident%20DESC&outFields=*&returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPoint

  exports.notifyUsers = functions.pubsub
    .schedule("every 1 minutes")
    .onRun(async (message) => {
      try {
        const response = await axios.get(
          "https://maps.phoenix.gov/phxfire/rest/services/Active_Incidents__Public/MapServer/0/query?f=json&cacheHint=true&resultOffset=0&resultRecordCount=100&where=1%3D1&orderByFields=Incident%20DESC&outFields=*&returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPoint"
        );

        if (response?.data?.error?.code == 500) {
          logger.log("error from API - returning..");
          return;
        }

        const incidents = response?.data?.features?.map((feature) => ({
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
                Array.from(incident.stations).some((station) =>
                  user.stations.includes(station)
                )
            )
            .map((incident) => ({
              ...incident,
              alertStations: Array.from(incident.stations).filter((station) =>
                user.stations.includes(station)
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
