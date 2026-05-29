type Sentiment = "positive" | "neutral" | "negative";

const SENTIMENT_LABEL: Record<Sentiment, string> = {
  positive: "Positive",
  neutral:  "Neutral",
  negative: "Negative",
};

const SENTIMENT_STYLE: Record<Sentiment, string> = {
  positive: "bg-green-100 text-green-700",
  neutral:  "bg-gray-100 text-gray-600",
  negative: "bg-red-100 text-red-700",
};

export function FeedbackDetailModal({
  entry,
  onClose,
}: {
  entry: any;
  onClose: () => void;
}) {
  const sentiment = entry.sentiment as Sentiment;
  const dateStr = entry.createdAt
    ? new Date(entry.createdAt).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })
    : null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div className="w-full max-w-lg rounded-xl bg-white shadow-xl">
        {/* Header */}
        <div className="flex items-start justify-between border-b border-gray-100 px-5 py-4">
          <div className="min-w-0">
            <p className="text-sm font-semibold text-gray-900">{entry.clientName}</p>
            {entry.featureName && (
              <p className="mt-0.5 text-xs text-gray-400">{entry.featureName}</p>
            )}
          </div>
          <button
            onClick={onClose}
            className="ml-4 shrink-0 rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
          >
            <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="space-y-4 px-5 py-4">
          {/* Sentiment + blocking */}
          <div className="flex flex-wrap items-center gap-2">
            <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${SENTIMENT_STYLE[sentiment] ?? SENTIMENT_STYLE.neutral}`}>
              {SENTIMENT_LABEL[sentiment] ?? sentiment}
            </span>
            {entry.isGatingRequest && (
              <span className="inline-flex items-center rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-700">
                Blocking request
              </span>
            )}
          </div>

          {/* Notes */}
          {entry.notes ? (
            <div>
              <p className="mb-1 text-xs font-medium text-gray-400 uppercase tracking-wide">Notes</p>
              <p className="text-sm text-gray-800 whitespace-pre-wrap">{entry.notes}</p>
            </div>
          ) : (
            <p className="text-sm text-gray-300 italic">No notes recorded.</p>
          )}

          {/* Gating description */}
          {entry.isGatingRequest && entry.gatingDescription && (
            <div>
              <p className="mb-1 text-xs font-medium text-gray-400 uppercase tracking-wide">Blocking description</p>
              <p className="text-sm text-gray-800 whitespace-pre-wrap">{entry.gatingDescription}</p>
            </div>
          )}

          {/* Meta row */}
          <div className="flex flex-wrap gap-x-6 gap-y-1 border-t border-gray-100 pt-3 text-xs text-gray-400">
            {entry.feedbackProviderName && (
              <span>Provider: <span className="text-gray-600">{entry.feedbackProviderName}</span></span>
            )}
            {dateStr && (
              <span>Date: <span className="text-gray-600">{dateStr}</span></span>
            )}
          </div>

          {/* JIRA link */}
          {entry.jiraTicketUrl && (
            <a
              href={entry.jiraTicketUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-xs font-medium text-blue-600 hover:text-blue-800"
            >
              View JIRA ticket →
            </a>
          )}
        </div>
      </div>
    </div>
  );
}
