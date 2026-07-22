"""Back-compat export for Milestone 8 ReportGenerator."""

from app.services.report import ReportGenerator, ReportGenerationResult

__all__ = ["ReportGenerator", "ReportGenerationResult"]
