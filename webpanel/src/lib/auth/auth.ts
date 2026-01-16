import {getServerSession} from "next-auth";
import {GetServerSidePropsContext, NextApiRequest, NextApiResponse} from "next";
import {authOptions} from "@/app/api/auth/[...nextauth]/route";

export async function getApplicationSession(...args:
                                                | [GetServerSidePropsContext["req"], GetServerSidePropsContext["res"]]
                                                | [NextApiRequest, NextApiResponse]
                                                | []
) {
    return getServerSession(...args, authOptions)
}