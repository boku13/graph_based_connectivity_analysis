"""
Report Generator for RTL Connectivity Analysis
Generates formatted analysis reports
"""

from typing import Dict, List, Tuple
from graph_builder import DependencyGraph
import json
from datetime import datetime


class ReportGenerator:
    """Generate analysis reports for RTL connectivity analysis"""
    
    def __init__(self, graph: DependencyGraph):
        self.graph = graph
        self.stats = graph.get_statistics()
    
    def generate_text_report(self, output_file: str, top_k: int = 10) -> None:
        """Generate a comprehensive text report"""
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Header
            f.write("=" * 80 + "\n")
            f.write("RTL CONNECTIVITY ANALYSIS REPORT\n")
            f.write("=" * 80 + "\n")
            f.write(f"Module: {self.stats['module_name']}\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")
            
            # Overall Statistics
            f.write("OVERALL STATISTICS\n")
            f.write("-" * 80 + "\n")
            f.write(f"Total Signals: {self.stats['total_signals']}\n")
            f.write(f"Total Dependencies: {self.stats['total_dependencies']}\n")
            f.write(f"Average Fan-In: {self.stats['average_fan_in']}\n")
            f.write(f"Average Fan-Out: {self.stats['average_fan_out']}\n\n")
            
            # Signal Type Distribution
            f.write("Signal Type Distribution:\n")
            for sig_type, count in sorted(self.stats['signal_types'].items()):
                f.write(f"  {sig_type:12s}: {count:4d}\n")
            f.write("\n")
            
            # Top-K Signals by Fan-In
            f.write("=" * 80 + "\n")
            f.write(f"TOP-{top_k} SIGNALS BY FAN-IN (Incoming-Busy)\n")
            f.write("=" * 80 + "\n\n")
            
            top_fan_in = self.graph.get_top_k_fan_in(top_k)
            
            if top_fan_in:
                for rank, (signal, count, drivers) in enumerate(top_fan_in, 1):
                    signal_info = self.graph.get_signal_info(signal)
                    f.write(f"{rank}. Signal: {signal}\n")
                    f.write(f"   Type: {signal_info.signal_type if signal_info else 'unknown'}\n")
                    f.write(f"   Width: {signal_info.width if signal_info else '1'}\n")
                    f.write(f"   Fan-In Count: {count}\n")
                    f.write(f"   Driven By:\n")
                    for driver in drivers:
                        f.write(f"     - {driver}\n")
                    f.write("\n")
            else:
                f.write("No signals with fan-in found.\n\n")
            
            # Top-K Signals by Fan-Out
            f.write("=" * 80 + "\n")
            f.write(f"TOP-{top_k} SIGNALS BY FAN-OUT (Outgoing-Busy)\n")
            f.write("=" * 80 + "\n\n")
            
            top_fan_out = self.graph.get_top_k_fan_out(top_k)
            
            if top_fan_out:
                for rank, (signal, count, loads) in enumerate(top_fan_out, 1):
                    signal_info = self.graph.get_signal_info(signal)
                    f.write(f"{rank}. Signal: {signal}\n")
                    f.write(f"   Type: {signal_info.signal_type if signal_info else 'unknown'}\n")
                    f.write(f"   Width: {signal_info.width if signal_info else '1'}\n")
                    f.write(f"   Fan-Out Count: {count}\n")
                    f.write(f"   Drives:\n")
                    for load in loads:
                        f.write(f"     - {load}\n")
                    f.write("\n")
            else:
                f.write("No signals with fan-out found.\n\n")
            
            # All Signal Connectivity
            f.write("=" * 80 + "\n")
            f.write("COMPLETE SIGNAL CONNECTIVITY TABLE\n")
            f.write("=" * 80 + "\n\n")
            
            metrics = self.graph.compute_connectivity_metrics()
            
            # Sort by signal name
            for signal in sorted(metrics.keys()):
                m = metrics[signal]
                f.write(f"Signal: {signal}\n")
                f.write(f"  Type: {m['signal_type']}, Width: {m['width']}\n")
                f.write(f"  Fan-In: {m['fan_in_count']}, Fan-Out: {m['fan_out_count']}\n")
                
                if m['fan_in_signals']:
                    f.write(f"  Driven by: {', '.join(m['fan_in_signals'])}\n")
                
                if m['fan_out_signals']:
                    f.write(f"  Drives: {', '.join(m['fan_out_signals'])}\n")
                
                f.write("\n")
            
            f.write("=" * 80 + "\n")
            f.write("END OF REPORT\n")
            f.write("=" * 80 + "\n")
    
    def generate_json_report(self, output_file: str, top_k: int = 10) -> None:
        """Generate a JSON format report"""
        
        report = {
            'metadata': {
                'module_name': self.stats['module_name'],
                'generated': datetime.now().isoformat(),
                'top_k': top_k
            },
            'statistics': self.stats,
            'top_fan_in': [],
            'top_fan_out': [],
            'all_signals': {}
        }
        
        # Top Fan-In
        top_fan_in = self.graph.get_top_k_fan_in(top_k)
        for signal, count, drivers in top_fan_in:
            signal_info = self.graph.get_signal_info(signal)
            report['top_fan_in'].append({
                'signal': signal,
                'type': signal_info.signal_type if signal_info else 'unknown',
                'width': signal_info.width if signal_info else '1',
                'fan_in_count': count,
                'drivers': drivers
            })
        
        # Top Fan-Out
        top_fan_out = self.graph.get_top_k_fan_out(top_k)
        for signal, count, loads in top_fan_out:
            signal_info = self.graph.get_signal_info(signal)
            report['top_fan_out'].append({
                'signal': signal,
                'type': signal_info.signal_type if signal_info else 'unknown',
                'width': signal_info.width if signal_info else '1',
                'fan_out_count': count,
                'loads': loads
            })
        
        # All signals
        metrics = self.graph.compute_connectivity_metrics()
        report['all_signals'] = metrics
        
        # Write JSON
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2)
    
    def generate_summary_report(self) -> str:
        """Generate a brief summary report as string"""
        lines = []
        lines.append(f"Module: {self.stats['module_name']}")
        lines.append(f"Signals: {self.stats['total_signals']}, Dependencies: {self.stats['total_dependencies']}")
        lines.append(f"Avg Fan-In: {self.stats['average_fan_in']}, Avg Fan-Out: {self.stats['average_fan_out']}")
        
        top_fan_in = self.graph.get_top_k_fan_in(3)
        if top_fan_in:
            lines.append(f"Top Fan-In: {top_fan_in[0][0]} ({top_fan_in[0][1]})")
        
        top_fan_out = self.graph.get_top_k_fan_out(3)
        if top_fan_out:
            lines.append(f"Top Fan-Out: {top_fan_out[0][0]} ({top_fan_out[0][1]})")
        
        return " | ".join(lines)
