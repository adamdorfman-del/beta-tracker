import { Router, type IRouter } from "express";
import { requireBirdeyeAuth } from "../middlewares/requireBirdeyeAuth";
import { requireRole } from "../middlewares/requireRole";
import healthRouter from "./health";
import featuresRouter from "./features";
import enrollmentsRouter from "./enrollments";
import clientsRouter from "./clients";
import batchesRouter from "./batches";
import reportsRouter from "./reports";
import usersRouter from "./users";
import meRouter from "./me";
import feedbackRouter from "./feedback";
import testimonialsRouter from "./testimonials";
import authRouter from "./auth";
import auditLogsRouter from "./auditLogs";

const router: IRouter = Router();

router.use(healthRouter);

router.use(requireBirdeyeAuth);

router.use("/me", meRouter);
router.use("/auth", authRouter);
router.use("/features", featuresRouter);
router.use("/enrollments", enrollmentsRouter);
router.use("/clients", clientsRouter);
router.use("/batches", batchesRouter);
router.use("/reports", reportsRouter);
router.use("/users", usersRouter);
router.use("/feedback", feedbackRouter);
router.use("/testimonials", testimonialsRouter);
router.use("/audit-logs", auditLogsRouter);

export default router;
