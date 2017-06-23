# METRICS: PERCENTILE HELPER
# --------------------------------------------------------------------------
# Helper class to calculate percentiles.
class Percentile

    calculate: (durations, perc) ->
        return findK durations.concat(), 0, durations.length, Math.ceil(durations.length * perc / 100) - 1

    swap = (data, i, j) ->
        return if i is j

        tmp = data[j]
        data[j] = data[i]
        data[i] = tmp

    partition = (data, start, end) ->
        i = start + 1
        j = start

        while i < end
            swap data, i, ++j if data[i] < data[start]
            i++

        swap data, start, j
        return j

    findK = (data, start, end, k) ->
        while start < end
            pos = partition data, start, end

            if pos is k
                return data[k]
            if pos > k
                end = pos
            else
                start = pos + 1

        return null

# Singleton implementation
# -----------------------------------------------------------------------------
Percentile.getInstance = ->
    @instance = new Percentile() if not @instance?
    return @instance

module.exports = exports = Percentile.getInstance()
