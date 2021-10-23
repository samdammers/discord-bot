"""This script updates a bucket policy to append IP or reset them"""
from pprint import pprint
import os
import boto3


def ecs_actions(ecs_client, action):
    """
    Either STOP or START EC2 Instance
    :param ecs_client:
    :param action:
    :return:
    """

    if action == "STOP":
        resp = ecs_client.update_service(
            cluster=os.getenv("CLUSTER_NAME"),
            service=os.getenv("SERVICE_NAME"),
            desiredCount=0
        )
        pprint(resp)
        return

    if action == "START":
        resp = ecs_client.update_service(
            cluster=os.getenv("CLUSTER_NAME"),
            service=os.getenv("SERVICE_NAME"),
            desiredCount=1
        )
        pprint(resp)
        return

    raise RuntimeError("Did not receive action of START|STOP")


def lambda_handler(event, context):
    # pylint: disable=unused-argument
    """ Lambda Handler, handles scheduled timer events and Cloudtrail CreateLogGroup events """

    sess = boto3.session.Session()
    detail_type = event.get("detail-type", "")
    route_key = event.get("routeKey", "")

    if route_key == "GET /discord-bot/stop" or route_key == "GET /discord-bot/restart" or detail_type == "Scheduled Event":
        ecs_actions(sess.client("ecs"), "STOP")

    if route_key == "GET /discord-bot/start" or route_key == "GET /discord-bot/restart":
        ecs_actions(sess.client("ecs"), "START")

    return
